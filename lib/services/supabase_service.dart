import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço centralizado para gerenciar a comunicação com o Supabase.
/// Implementa o padrão Singleton para manter o cache de dados acessível em todo o app.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  // Cache em memória para evitar loading excessivo e permitir acesso instantâneo
  List<dynamic> imcHistory = [];
  Map<String, dynamic> dietData = {};
  List<dynamic> trainingHistory = [];

  bool isLoaded = false;

  /// Puxa todos os dados do banco de uma vez só.
  /// Ideal para ser chamado na SplashScreen.
  Future<void> loadAllData() async {
    try {
      final response = await _supabase.from('app_data').select();

      for (var row in response) {
        final String key = row['id_key'];
        final dynamic data = row['data'];

        if (key == 'imc_history') imcHistory = List.from(data ?? []);
        if (key == 'dieta_do_usuario') dietData = Map<String, dynamic>.from(data ?? {});
        if (key == 'training_history') trainingHistory = List.from(data ?? []);
      }
      isLoaded = true;
      debugPrint("Sincronização com Supabase concluída.");
    } catch (e) {
      debugPrint("Erro ao carregar dados do Supabase: $e");
      // Em caso de erro, poderíamos carregar do cache local (SharedPreferences)
    }
  }

  // --- MÉTODOS DE PERSISTÊNCIA ESPECÍFICOS ---

  Future<void> saveIMC(List<dynamic> newHistory) async {
    imcHistory = newHistory;
    await _supabase.from('app_data').upsert({
      'id_key': 'imc_history',
      'data': imcHistory,
    });
  }

  Future<void> saveDiet(Map<String, dynamic> newDiet) async {
    dietData = newDiet;
    await _supabase.from('app_data').upsert({
      'id_key': 'dieta_do_usuario',
      'data': dietData,
    });
  }

  Future<void> saveTraining(List<dynamic> newTrainings) async {
    trainingHistory = newTrainings;
    await _supabase.from('app_data').upsert({
      'id_key': 'training_history',
      'data': trainingHistory,
    });
  }

  // Nota: No futuro, adicione o user_id nas consultas para que cada usuário
  // tenha seus próprios dados privadamente.
}
