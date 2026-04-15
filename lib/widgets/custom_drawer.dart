import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/diet_screen.dart';
import '../screens/history_screen.dart';
import '../screens/training_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: Colors.green),
            title: const Text('Calculadora de IMC'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.green),
            title: const Text('Histórico de Evolução'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu, color: Colors.green),
            title: const Text('Minha Dieta'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DietScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.green),
            title: const Text('Meus Treinos'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TrainingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}