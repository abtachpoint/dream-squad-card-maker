import 'package:flutter/material.dart';
import '../app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool signUp = false;

  Future<void> _emailLogin() async {
    final mail = email.text.trim();
    if (!mail.contains('@') || password.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email and at least 4 characters password.')));
      return;
    }
    await appState.login(name: mail.split('@').first, mail: mail, method: 'Email');
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(colors: [Color(0xFF6C4DFF), Color(0xFF00B7FF)]),
                    ),
                    child: const Icon(Icons.style_rounded, size: 44),
                  ),
                  const SizedBox(height: 18),
                  const Text('Dream Squad Card Maker', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Create custom football cards and build your dream squad.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: () => appState.login(name: 'Google Player', mail: 'google@trial.local', method: 'Google'),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: Colors.white38))), Expanded(child: Divider())]),
                  ),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(onPressed: _emailLogin, child: Text(signUp ? 'Create account' : 'Login')),
                  ),
                  TextButton(onPressed: () => setState(() => signUp = !signUp), child: Text(signUp ? 'Already have an account? Login' : 'New here? Sign up')),
                  TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trial build: password reset UI is ready; Firebase will be connected in the production build.'))), child: const Text('Forgot password?')),
                  const SizedBox(height: 18),
                  const Text('TRIAL BUILD • Login is stored locally in this APK.', style: TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
