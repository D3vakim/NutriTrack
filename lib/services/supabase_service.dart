import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService extends ChangeNotifier {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  List<dynamic> imcHistory = [];
  Map<String, dynamic> dietData = {};
  List<dynamic> trainingHistory = [];
  Map<String, dynamic> dietLog = {};
  Map<String, dynamic> lastSuggestedDiet = {};

  bool isLoaded = false;

  // ✅ Agora pega o ID real e permanente do usuário logado
  Future<String> _getDeviceId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      return user.id;
    }
    throw Exception('Usuário não autenticado');
  }

  // --- MÉTODOS DE AUTENTICAÇÃO ---
  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpa o cache local para o próximo usuário

    // Reseta as variáveis da memória
    imcHistory = [];
    dietData = {};
    trainingHistory = [];
    dietLog = {};
    isLoaded = false;
    notifyListeners();
  }

  // --- CARREGAMENTO DE DADOS ---
  Future<void> loadAllData() async {
    try {
      final deviceId = await _getDeviceId(); // Exige que esteja logado
      await _loadFromLocal();
      isLoaded = true;
      notifyListeners();

      final response = await _supabase
          .from('app_data')
          .select()
          .eq('device_id', deviceId)
          .inFilter('id_key', ['imc_history', 'dieta_do_usuario', 'training_history', 'diet_log']);

      bool changed = false;

      for (var row in response) {
        final String key = row['id_key'];
        final dynamic cloudData = row['data'];

        if (key == 'imc_history' && cloudData != null) {
          imcHistory = List.from(cloudData);
          await _saveToLocal('imc_history', imcHistory);
          changed = true;
        } else if (key == 'dieta_do_usuario' && cloudData != null) {
          dietData = Map<String, dynamic>.from(cloudData);
          await _saveToLocal('dieta_do_usuario', dietData);
          changed = true;
        } else if (key == 'training_history' && cloudData != null) {
          trainingHistory = List.from(cloudData);
          await _saveToLocal('training_history', trainingHistory);
          changed = true;
        } else if (key == 'diet_log' && cloudData != null) {
          dietLog = Map<String, dynamic>.from(cloudData);
          await _saveToLocal('diet_log', dietLog);
          changed = true;
        }
      }

      if (changed) notifyListeners();
      debugPrint('✅ Dados do usuário carregados da nuvem!');
    } catch (e) {
      debugPrint('⚠️ Erro ao buscar da nuvem: $e');
    }
  }

  // --- PERSISTÊNCIA LOCAL E NUVEM (Mantido igual) ---
  Future<void> _saveToLocal(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_$key', jsonEncode(data));
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final imcRaw = prefs.getString('local_imc_history');
    if (imcRaw != null) imcHistory = jsonDecode(imcRaw);
    final dietRaw = prefs.getString('local_dieta_do_usuario');
    if (dietRaw != null) dietData = jsonDecode(dietRaw);
    final trainingRaw = prefs.getString('local_training_history');
    if (trainingRaw != null) trainingHistory = jsonDecode(trainingRaw);
    final logRaw = prefs.getString('local_diet_log');
    if (logRaw != null) dietLog = jsonDecode(logRaw);
    final lastSugRaw = prefs.getString('local_last_suggested_diet');
    if (lastSugRaw != null) lastSuggestedDiet = jsonDecode(lastSugRaw);
  }

  Future<void> saveIMC(List<dynamic> newHistory) async {
    imcHistory = newHistory;
    await _saveToLocal('imc_history', imcHistory);
    await _safeSync('imc_history', imcHistory);
    notifyListeners();
  }

  Future<void> saveDiet(Map<String, dynamic> newDiet) async {
    dietData = newDiet;
    await _saveToLocal('dieta_do_usuario', dietData);
    await _safeSync('dieta_do_usuario', dietData);
    notifyListeners();
  }

  Future<void> saveTraining(List<dynamic> newTrainings) async {
    trainingHistory = newTrainings;
    await _saveToLocal('training_history', trainingHistory);
    await _safeSync('training_history', trainingHistory);
    notifyListeners();
  }

  Future<void> saveDietLog(Map<String, dynamic> newLog) async {
    dietLog = newLog;
    await _saveToLocal('diet_log', dietLog);
    await _safeSync('diet_log', dietLog);
    notifyListeners();
  }

  Future<void> saveLastSuggestedDiet(Map<String, dynamic> diet) async {
    lastSuggestedDiet = diet;
    await _saveToLocal('last_suggested_diet', diet);
  }

  Future<void> _safeSync(String key, dynamic data) async {
    try {
      final deviceId = await _getDeviceId();

      final existing = await _supabase
          .from('app_data')
          .select('id_key')
          .eq('id_key', key)
          .eq('device_id', deviceId)
          .limit(1);

      if (existing.isNotEmpty) {
        await _supabase.from('app_data').update({'data': data}).eq('id_key', key).eq('device_id', deviceId);
      } else {
        await _supabase.from('app_data').insert({'device_id': deviceId, 'id_key': key, 'data': data});
      }
      debugPrint('✅ Sincronizado com a nuvem: $key');
    } catch (e) {
      debugPrint('❌ Falha ao sincronizar $key: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSuggestedDiet() async {
    try {
      final response = await _supabase.from('suggested_diet').select('data').eq('id', 1).maybeSingle();
      if (response != null && response['data'] != null) return response['data'] as Map<String, dynamic>;
      return null;
    } catch (e) {
      return null;
    }
  }
}