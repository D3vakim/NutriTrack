import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
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
    _initAppData();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _contentController.forward();
    }
  }

  Future<void> _initAppData() async {
    try {
      // Tenta sincronizar os dados, mas não trava em caso de erro
      await SupabaseService().loadAllData();
    } catch (e) {
      debugPrint("Erro ao carregar dados na Splash: $e");
    }

    // Tempo mínimo de permanência para apreciar o design
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    
    // Navega para o MainScaffold (BottomNavigationBar)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoAnimation,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
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
