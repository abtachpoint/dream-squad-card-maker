import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/coin_badge.dart';
import 'my_cards_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            const Row(children: [Expanded(child: Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), CoinBadge()]),
            const SizedBox(height: 20),
            Center(
              child: Column(children: [
                CircleAvatar(radius: 38, child: Text(appState.userName.isEmpty ? 'P' : appState.userName[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
                const SizedBox(height: 10),
                Text(appState.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text(appState.email, style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 4),
                Text('Login: ${appState.loginMethod}', style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ]),
            ),
            const SizedBox(height: 24),
            ListTile(leading: const Icon(Icons.collections_bookmark_rounded), title: const Text('My Cards'), subtitle: Text('${appState.cards.length} saved this session'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsScreen()))),
            const ListTile(leading: Icon(Icons.cloud_done_outlined), title: Text('Sync Status'), subtitle: Text('Trial: local storage • Cloud sync pending')),
            const ListTile(leading: Icon(Icons.receipt_long_rounded), title: Text('Purchase History'), subtitle: Text('Available after Google Play IAP setup')),
            const ListTile(leading: Icon(Icons.settings_rounded), title: Text('Account Settings'), subtitle: Text('Google + Email/Password planned for Firebase')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () async => appState.logout(), icon: const Icon(Icons.logout_rounded), label: const Text('Logout')),
            const SizedBox(height: 28),
            const Center(child: Text('Developer: ABIR AHOMOD', style: TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: .6))),
            const SizedBox(height: 4),
            const Center(child: Text('Dream Squad Card Maker • Trial 0.1.0', style: TextStyle(fontSize: 10, color: Colors.white24))),
          ],
        ),
      ),
    );
  }
}
