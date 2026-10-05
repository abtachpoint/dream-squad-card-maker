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

  String? startupError;

  try {
    await Firebase.initializeApp();
    await appState.initialize();
  } catch (error, stackTrace) {
    debugPrint('Startup initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    startupError = error.toString();
  }

  runApp(DreamSquadApp(startupError: startupError));

  if (startupError == null) {
    unawaited(_initializeBackgroundServices());
  }
}

Future<void> _initializeBackgroundServices() async {
  try {
    await MobileAds.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('AdMob initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await adService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Rewarded ad initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await purchaseService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Purchase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class DreamSquadApp extends StatelessWidget {
  const DreamSquadApp({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7757FF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF090A0E),
        cardTheme: const CardThemeData(color: Color(0xFF12141B)),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF151821),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: startupError != null
          ? StartupErrorScreen(error: startupError!)
          : AnimatedBuilder(
              animation: appState,
              builder: (context, _) {
                if (appState.accountLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return appState.loggedIn
                    ? const MainShell()
                    : const LoginScreen();
              },
            ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App could not start',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'A startup service failed to initialize. This screen prevents the app from closing so the exact error can be identified.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  SelectableText(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
