import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'diet_screen.dart';
import 'training_screen.dart';
import '../widgets/custom_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Home(),
    const HistoryScreen(),
    const DietScreen(),
    const TrainingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculadora'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Evolução'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Dieta'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Treinos'),
        ],
      ),
    );
  }
}
