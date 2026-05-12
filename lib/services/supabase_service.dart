import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService extends ChangeNotifier {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  // Cache em memória para o app rodar liso e rápido
  List<dynamic> imcHistory = [];
  Map<String, dynamic> dietData = {};
  List<dynamic> trainingHistory = [];
  Map<String, dynamic> lastSuggestedDiet = {};

  bool isLoaded = false;

  /// Carrega tudo ao iniciar o app (Splash Screen)
  Future<void> loadAllData() async {
    // 1. Carrega o que tem salvo no celular rápido
    await _loadFromLocal();
    isLoaded = true;
    notifyListeners();

    // 2. Puxa as atualizações do Supabase (Tabela app_data)
    try {
      final response = await _supabase
          .from('app_data')
          .select()
          .inFilter('id_key', ['imc_history', 'dieta_do_usuario', 'training_history']);

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
        }
      }

      if (changed) {
        notifyListeners();
      }
      debugPrint('✅ Dados de uso carregados da nuvem!');
    } catch (e) {
      debugPrint('⚠️ Trabalhando Offline (Erro ao buscar da nuvem): $e');
    }
  }

  // --- PERSISTÊNCIA LOCAL ---
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

    final lastSugRaw = prefs.getString('local_last_suggested_diet');
    if (lastSugRaw != null) lastSuggestedDiet = jsonDecode(lastSugRaw);
  }

  // --- MÉTODOS DE SALVAR (Que as telas chamam) ---
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

  Future<void> saveLastSuggestedDiet(Map<String, dynamic> diet) async {
    lastSuggestedDiet = diet;
    await _saveToLocal('last_suggested_diet', diet);
  }

  /// ✅ Sincroniza com o Supabase EXATAMENTE no formato da sua tabela 'app_data'
  /// ✅ Sincroniza com a nuvem e ignora o erro de múltiplas linhas duplicadas (Erro 406)
  Future<void> _safeSync(String key, dynamic data) async {
    try {
      // 1. Busca como uma lista, pegando no máximo 1 (assim ele nunca dá o erro 406)
      final existing = await _supabase
          .from('app_data')
          .select('id_key')
          .eq('id_key', key)
          .limit(1);

      // 'existing' agora é uma lista. Se não for vazia, significa que a chave existe.
      if (existing.isNotEmpty) {
        // 2. Atualiza TODAS as linhas que tenham essa chave (mesmo que tenham 9 cópias perdidas)
        await _supabase
            .from('app_data')
            .update({'data': data})
            .eq('id_key', key);
      } else {
        // 3. Se não tem nenhuma, insere a primeira
        await _supabase
            .from('app_data')
            .insert({'id_key': key, 'data': data});
      }

      debugPrint('✅ Sincronizado com a nuvem: $key');
    } catch (e) {
      debugPrint('❌ Falha ao sincronizar $key: $e');
    }
  }  /// ✅ Busca a dieta sugerida da SUA TABELA NOVA 'suggested_diet'
  Future<Map<String, dynamic>?> fetchSuggestedDiet() async {
    try {
      final response = await _supabase
          .from('suggested_diet')
          .select('data')
          .eq('id', 1) // Busca exatamente a linha que você mostrou na foto
          .maybeSingle();

      if (response != null && response['data'] != null) {
        debugPrint('✅ Dieta sugerida puxada do banco!');
        return response['data'] as Map<String, dynamic>;
      } else {
        debugPrint('⚠️ Nenhuma dieta encontrada no banco.');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar dieta sugerida: $e');
      return null;
    }
  }
}