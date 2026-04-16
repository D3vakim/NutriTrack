import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ATUALIZAÇÃO: Usando a nova URL do projeto (sem o sufixo da tabela)
  await Supabase.initialize(
    url: 'https://hhwfpeluesyqqwmjijjj.supabase.co',
    anonKey: 'sb_publishable_pG7iNmXUH6pWLqAiE4B0Rw_iB-nFyWt', // Verifique se esta chave ainda é a mesma no novo projeto!
  );

  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
