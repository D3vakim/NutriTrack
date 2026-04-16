import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Serviço centralizado para gerenciar a comunicação Offline e Online.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;
  String? _deviceId;

  // Cache em memória para acesso instantâneo na UI
  List<dynamic> imcHistory = [];
  Map<String, dynamic> dietData = {};
  List<dynamic> trainingHistory = [];

  bool isLoaded = false;

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('user_device_id');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('user_device_id', _deviceId!);
    }
  }

  /// Carrega dados locais (imediato) e depois sincroniza com a nuvem (conflitos)
  Future<void> loadAllData() async {
    if (_deviceId == null) await _initDeviceId();
    
    // 1. Primeiro carrega o que tem no celular (Offline First)
    await _loadFromLocal();
    isLoaded = true;

    // 2. Tenta buscar da nuvem e resolver conflitos
    try {
      final response = await _supabase
          .from('app_data')
          .select()
          .eq('device_id', _deviceId!);

      if (response.isNotEmpty) {
        for (var row in response) {
          final String key = row['id_key'];
          final dynamic cloudData = row['data'];

          if (key == 'imc_history') {
            imcHistory = _mergeLists(imcHistory, List.from(cloudData ?? []));
            await _saveToLocal('imc_history', imcHistory);
          } else if (key == 'dieta_do_usuario') {
            dietData = cloudData ?? dietData; // Dieta: Nuvem sobrescreve se existir
            await _saveToLocal('dieta_do_usuario', dietData);
          } else if (key == 'training_history') {
            trainingHistory = _mergeLists(trainingHistory, List.from(cloudData ?? []));
            await _saveToLocal('training_history', trainingHistory);
          }
        }
        // 3. Após o merge, envia a versão final unificada de volta para a nuvem
        await syncToCloud();
      }
      debugPrint("Sincronização completa realizada.");
    } catch (e) {
      debugPrint("Offline: Não foi possível sincronizar com a nuvem agora ($e)");
    }
  }

  /// Une duas listas de históricos sem duplicar registros da mesma data.
  List<dynamic> _mergeLists(List<dynamic> local, List<dynamic> cloud) {
    final Map<String, dynamic> merged = {};
    
    // Adiciona itens da nuvem primeiro
    for (var item in cloud) {
      merged[item['date']] = item;
    }
    
    // Adiciona itens locais (se houver conflito de data, o local vence pois é o mais recente)
    for (var item in local) {
      merged[item['date']] = item;
    }

    final result = merged.values.toList();
    // Ordenar por data (opcional aqui, já que as telas ordenam)
    return result;
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
  }

  // --- MÉTODOS PÚBLICOS DE SALVAMENTO ---

  Future<void> saveIMC(List<dynamic> newHistory) async {
    imcHistory = newHistory;
    await _saveToLocal('imc_history', imcHistory);
    _safeSync('imc_history', imcHistory);
  }

  Future<void> saveDiet(Map<String, dynamic> newDiet) async {
    dietData = newDiet;
    await _saveToLocal('dieta_do_usuario', dietData);
    _safeSync('dieta_do_usuario', dietData);
  }

  Future<void> saveTraining(List<dynamic> newTrainings) async {
    trainingHistory = newTrainings;
    await _saveToLocal('training_history', trainingHistory);
    _safeSync('training_history', trainingHistory);
  }

  /// Tenta sincronizar um dado específico sem travar a UI se falhar
  Future<void> _safeSync(String key, dynamic data) async {
    try {
      await _supabase.from('app_data').upsert({
        'device_id': _deviceId,
        'id_key': key,
        'data': data,
      });
    } catch (e) {
      debugPrint("Falha ao sincronizar $key para a nuvem. Ficará salvo localmente.");
    }
  }

  /// Força o envio de todo o cache local para a nuvem
  Future<void> syncToCloud() async {
    await _safeSync('imc_history', imcHistory);
    await _safeSync('dieta_do_usuario', dietData);
    await _safeSync('training_history', trainingHistory);
  }
}
