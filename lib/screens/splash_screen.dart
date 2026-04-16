import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Inicia o carregamento dos dados do Supabase enquanto a animação roda
    _initAppData();
  }

  Future<void> _initAppData() async {
    // Carrega todos os dados do banco para o cache do serviço
    await SupabaseService().loadAllData();

    if (_controller.isCompleted) {
      _navigateToHome();
    } else {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _navigateToHome();
        }
      });
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}