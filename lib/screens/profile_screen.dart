import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/app_notice.dart';
import '../widgets/coin_badge.dart';
import 'my_cards_screen.dart';
import 'my_squads_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: appState.userName);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(controller: controller, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.isEmpty) return;
    try {
      await appState.updateDisplayName(next);
      if (context.mounted) {
        await showAppNotice(context, title: 'Name updated', message: 'Your display name has been saved.', icon: Icons.check_circle_rounded, accent: Colors.greenAccent);
      }
    } catch (_) {
      if (context.mounted) {
        await showAppNotice(context, title: 'Couldn’t update name', message: 'Please try again.', icon: Icons.error_outline_rounded, accent: Colors.redAccent);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign in again any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (yes == true) await appState.logout();
  }

  Future<void> _delete(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This removes your Dream Squad account data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await appState.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      await showAppNotice(
        context,
        title: 'Sign in again first',
        message: e.code == 'requires-recent-login' ? 'For security, log out and sign in again before deleting your account.' : (e.message ?? 'Please try again.'),
        icon: Icons.lock_outline_rounded,
        accent: Colors.orangeAccent,
      );
    } catch (_) {
      if (!context.mounted) return;
      await showAppNotice(context, title: 'Couldn’t delete account', message: 'Please try again.', icon: Icons.error_outline_rounded, accent: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
          children: [
            const Row(
              children: [
                Expanded(child: Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                CoinBadge(),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage: appState.photoUrl != null && appState.photoUrl!.isNotEmpty ? NetworkImage(appState.photoUrl!) : null,
                  child: appState.photoUrl == null || appState.photoUrl!.isEmpty ? const Icon(Icons.person_rounded, size: 34) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.userName.isEmpty ? 'Player' : appState.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(appState.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
                      const SizedBox(height: 3),
                      Text('${appState.loginMethod} sign-in', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => _editName(context), tooltip: 'Edit display name', icon: const Icon(Icons.edit_rounded)),
              ],
            ),
            const SizedBox(height: 22),
            _ProfileTile(icon: Icons.collections_bookmark_rounded, title: 'My Cards', subtitle: '${appState.cards.length} saved', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsScreen()))),
            _ProfileTile(icon: Icons.stadium_rounded, title: 'My Squads', subtitle: '${appState.squads.length} saved', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySquadsScreen()))),
            _ProfileTile(icon: Icons.monetization_on_rounded, title: 'Coin Balance', subtitle: '${appState.coins} coins', onTap: null),
            const SizedBox(height: 10),
            _ProfileTile(icon: Icons.logout_rounded, title: 'Log out', subtitle: 'Sign out of this account', onTap: () => _logout(context)),
            _ProfileTile(icon: Icons.delete_forever_rounded, title: 'Delete account', subtitle: 'Permanently remove this account', danger: true, onTap: () => _delete(context)),
            const SizedBox(height: 32),
            const Center(
              child: Text('Developer: ABIR AHOMOD', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
