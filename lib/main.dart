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
  runApp(const DreamSquadApp());
}

class DreamSquadApp extends StatelessWidget {
  const DreamSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6C63FF);
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
        scaffoldBackgroundColor: const Color(0xFF080A0F),
        cardTheme: const CardThemeData(color: Color(0xFF12151D)),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF151923),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: const _BootstrapGate(),
    );
  }
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  bool _ready = false;
  bool _working = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_error != null || !_working) {
      setState(() {
        _working = true;
        _error = null;
      });
    } else {
      _working = true;
      _error = null;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      await appState.initialize();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _working = false;
      });
      unawaited(_startBackgroundServices());
    } catch (error, stackTrace) {
      debugPrint('App bootstrap failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _working = false;
      });
    }
  }

  Future<void> _startBackgroundServices() async {
    try {
      await MobileAds.instance.initialize();
      await adService.initialize();
    } catch (error, stackTrace) {
      debugPrint('Ad service initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await purchaseService.initialize();
    } catch (error, stackTrace) {
      debugPrint('Purchase service initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
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
                    Image.asset('assets/images/app_icon.png', width: 96, height: 96),
                    const SizedBox(height: 18),
                    const Text(
                      'Couldn’t start the app',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Check your internet connection, then try again. If the problem continues, the error below can be used for troubleshooting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _working ? null : _bootstrap,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/images/app_icon.png', width: 88, height: 88),
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        if (appState.accountLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return appState.loggedIn ? const MainShell() : const LoginScreen();
      },
    );
  }
}
