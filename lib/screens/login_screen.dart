import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/app_notice.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool signUp = false;
  bool busy = false;
  bool hidePassword = true;

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      await showAppNotice(
        context,
        title: 'Couldn’t sign in',
        message: _authMessage(e),
        icon: Icons.error_outline_rounded,
        accent: Colors.redAccent,
      );
    } catch (_) {
      if (!mounted) return;
      await showAppNotice(
        context,
        title: 'Couldn’t sign in',
        message: 'Please check your connection and try again.',
        icon: Icons.error_outline_rounded,
        accent: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return e.message ?? 'Please try again.';
    }
  }

  Future<void> _emailAction() async {
    final mail = email.text.trim();
    final pass = password.text;
    if (!mail.contains('@') || pass.length < 6) {
      await showAppNotice(
        context,
        title: 'Check your details',
        message: 'Enter a valid email and a password with at least 6 characters.',
        icon: Icons.warning_amber_rounded,
        accent: Colors.orangeAccent,
      );
      return;
    }
    await _run(() async {
      if (signUp) {
        await appState.signUpWithEmail(mail, pass);
      } else {
        await appState.signInWithEmail(mail, pass);
      }
    });
  }

  Future<void> _googleAction() async {
    await _run(() async {
      await appState.signInWithGoogle();
    });
  }

  Future<void> _resetPassword() async {
    final mail = email.text.trim();
    if (!mail.contains('@')) {
      await showAppNotice(
        context,
        title: 'Enter your email',
        message: 'Type your account email first, then tap Forgot password.',
        icon: Icons.mail_outline_rounded,
        accent: Colors.orangeAccent,
      );
      return;
    }
    await _run(() async {
      await appState.sendPasswordReset(mail);
      if (!mounted) return;
      await showAppNotice(
        context,
        title: 'Reset email sent',
        message: 'Check your inbox for the password reset link.',
        icon: Icons.mark_email_read_rounded,
        accent: Colors.greenAccent,
      );
    });
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/images/app_icon.png', width: 88, height: 88),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Dream Squad Card Maker',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create custom football cards and build your dream squad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: busy ? null : _googleAction,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: Colors.white38)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  TextField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    enabled: !busy,
                    obscureText: hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: signUp ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                    onSubmitted: (_) => _emailAction(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidePassword = !hidePassword),
                        icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: busy ? null : _emailAction,
                      child: busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(signUp ? 'Create account' : 'Login'),
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => setState(() => signUp = !signUp),
                    child: Text(signUp ? 'Already have an account? Login' : 'New here? Sign up'),
                  ),
                  if (!signUp)
                    TextButton(
                      onPressed: busy ? null : _resetPassword,
                      child: const Text('Forgot password?'),
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
