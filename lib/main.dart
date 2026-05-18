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
        //cometário, Ajusta o tamanho dos componentes conforme o sistema (Android/iOS) — deixa o app mais nativo
        
        
        
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

        // cometário, Configuração padronizada da AppBar em todo o app Sugestão: adicionar iconTheme para definir cor dos ícones também, garante consistência
        
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: TextStyle(color: primaryColor),
          floatingLabelStyle: TextStyle(color: primaryColor),
        ),

        //cometário  Campos de entrada padronizados com a cor do app
 Sugestão: adicionar hintStyle e errorStyle para definir cor dos textos de dica e erro, deixa mais bonito e claro
        

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        //cometário  Cartões com design limpo, sem sombra e com borda
Sugestão: adicionar cor de sombra ou elevação leve se quiser dar destaque em algumas telas
        
        //cometário Botões padronizados, cor e formato definidos
 Sugestão: adicionar também estilo para OutlinedButton e TextButton, para todos os botões seguirem o mesmo padrão
        

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
  // cometário Define tamanho de texto fixo, evita que o app quebre se o usuário mudar configuração do celular
Cuidado: isso pode dificultar acessibilidade para pessoas que precisam de texto maior. Avalie se realmente precisa deixar fixo
  
      home: const SplashScreen(),
    );
  }
}
//comentário  Tela inicial definida corretamente
Sugestão: adicionar carregamento ou verificação de sessão do Supabase na SplashScreen, para já direcionar o usuário logado direto para a tela principal
  // cometário ### Resumo geral

 Pontos positivos:
- Estrutura limpa e organizada
- Tema todo padronizado (cores, botões, campos, barras)
- Usa Material3 e boas práticas de inicialização

 Pontos que precisam ser corrigidos:
- [ ] Mover URL e chave do Supabase para variáveis de ambiente (segurança essencial!)

 Melhorias recomendadas:
- Separar cores e temas em arquivos próprios (organização)
- Completar estilos para todos os tipos de botões
- Adicionar tratamento de acessibilidade no tamanho do texto
- Implementar verificação de sessão na tela de abertura
  
