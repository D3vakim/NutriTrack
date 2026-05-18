import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
// cometário,  PONTO CRÍTICO DE SEGURANÇA!
As chaves e URL do Supabase estão diretamente no código.
Nunca deixe valores sensíveis assim — use variáveis de ambiente ou arquivo .env (ex: pacote flutter_dotenv).
Isso evita que dados de acesso vazem se o código for compartilhado ou público.
  

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hhwfpeluesyqqwmjijjj.supabase.co',
    anonKey: 'sb_publishable_pG7iNmXUH6pWLqAiE4B0Rw_iB-nFyWt',
  );

  runApp(const NutriTrackApp());
}

class NutriTrackApp extends StatelessWidget {
  const NutriTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2E7D32);
    //cometário, Cor primária definida uma vez e reutilizada — boa prática
Sugestão: mover essa cor para uma classe separada de constantes (ex: app_colors.dart) para organizar melhor, pois poderá ser usada em várias telas
  

    return MaterialApp(
      title: 'NutriTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
        //cometário, Uso correto do ColorScheme do Material3, gera paleta automática
Observação: como já definiu a cor primária, está certo, mas poderia usar apenas o seedColor que ele já define tudo
        
        
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: TextStyle(color: primaryColor),
          floatingLabelStyle: TextStyle(color: primaryColor),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
