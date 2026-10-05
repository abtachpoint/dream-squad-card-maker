import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/coin_badge.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _watchDemoAd(BuildContext context) async {
    if (appState.adCountToday >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily rewarded-ad limit reached.')));
      return;
    }
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Expanded(child: Text('Trial rewarded ad...'))])));
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) Navigator.pop(context);
    final ok = await appState.rewardAd();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '+5 coins added' : 'Reward unavailable')));
  }

  @override
  Widget build(BuildContext context) {
    final packs = [100, 250, 550, 1200, 2500];
    return SafeArea(
      child: AnimatedBuilder(
        animation: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            const Row(children: [Expanded(child: Text('Coins & Rewards', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), CoinBadge()]),
            const SizedBox(height: 18),
            _RewardTile(
              icon: Icons.card_giftcard_rounded,
              title: 'Daily Reward',
              subtitle: appState.canClaimDaily ? '+10 coins available' : 'Claimed today',
              button: appState.canClaimDaily ? 'Claim' : 'Done',
              onTap: appState.canClaimDaily ? () async { await appState.claimDaily(); } : null,
            ),
            const SizedBox(height: 10),
            _RewardTile(
              icon: Icons.play_circle_fill_rounded,
              title: 'Rewarded Ad',
              subtitle: '+5 coins • ${appState.adCountToday}/2 today',
              button: appState.adCountToday >= 2 ? 'Limit' : 'Watch',
              onTap: appState.adCountToday >= 2 ? null : () => _watchDemoAd(context),
            ),
            const SizedBox(height: 24),
            const Text('Buy Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Trial APK: real Google Play IAP will be connected after product IDs are created in Play Console.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            ...packs.map((coins) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F)),
                    title: Text('$coins coins', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('IAP setup pending'),
                    trailing: const Icon(Icons.lock_clock_rounded),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IAP will be enabled after Play Console product setup.'))),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.icon, required this.title, required this.subtitle, required this.button, required this.onTap});
  final IconData icon;
  final String title, subtitle, button;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
          FilledButton.tonal(onPressed: onTap, child: Text(button)),
        ]),
      );
}
