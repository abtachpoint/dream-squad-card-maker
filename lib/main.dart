import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.load();
  runApp(const DreamSquadApp());
}

class DreamSquadApp extends StatelessWidget {
  const DreamSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7757FF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dream Squad Card Maker',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF090A0E),
        cardTheme: const CardThemeData(color: Color(0xFF12141B)),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF151821),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      home: AnimatedBuilder(
        animation: appState,
        builder: (context, _) => appState.loggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }
}
