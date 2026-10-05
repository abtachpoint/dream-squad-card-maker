import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_state.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  await appState.initialize();
  unawaited(adService.initialize());
  unawaited(purchaseService.initialize());
  runApp(const DreamSquadApp());
}

class DreamSquadApp extends StatelessWidget {
  const DreamSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7757FF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
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
        builder: (context, _) {
          if (appState.accountLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return appState.loggedIn ? const MainShell() : const LoginScreen();
        },
      ),
    );
  }
}
