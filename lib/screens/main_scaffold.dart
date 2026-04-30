import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'diet_screen.dart';
import 'training_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Home(),
    const HistoryScreen(),
    const DietScreen(),
    const TrainingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight_outlined),
              label: 'IMC',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Histórico',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              label: 'Dieta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              label: 'Treinos',
            ),
          ],
        ),
      ),
    );
  }
}
