import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'card_pack_screen.dart';
import 'squad_builder_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import '../widgets/create_card_icon.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onTabRequested: (i) => setState(() => index = i)),
      const CardPackScreen(embedded: true),
      const SquadBuilderScreen(embedded: true),
      const ShopScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: CreateCardIcon(size: 25), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.stadium_rounded), label: 'Squad'),
          NavigationDestination(icon: Icon(Icons.monetization_on_rounded), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
