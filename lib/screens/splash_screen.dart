import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'main_scaffold.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
// Uso correto do mixin para controlar múltiplas animações

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  // Declaração correta dos controladores e animações, poderia usar nomes mais curtos ou agrupar, mas está claro
  
  late AnimationController _contentController;
  late Animation<double> _logoAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoAnimation = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _contentAnimation = CurvedAnimation(parent: _contentController, curve: Curves.easeIn);

    _startAnimations();
    // Animações separadas em método próprio — código mais organizado
    
    _initAppData();
  }
  // Lógica de inicialização separada — ótima separação de responsabilidades
  

  void _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _contentController.forward();
    }
  }

  Future<void> _initAppData() async {
    // Dá tempo de ver a animação bonita
    await Future.delayed(const Duration(seconds: 2));

    // Verifica se existe uma sessão de login ativa e salva no celular
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Já está logado! Puxa os dados dele e vai pro app
      await SupabaseService().loadAllData();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      }
    } else {
      // Não está logado. Vai pra tela de Login
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Conteúdo central centralizado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      size: 80,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _contentAnimation,
                  child: Column(
                    children: [
                      const Text(
                        "NutriTrack",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sua saúde, acompanhada.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Seção de carregamento na parte inferior
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Column(
              children: [
                FadeTransition(
                  opacity: _contentAnimation,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(99),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Carregando seus dados...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
