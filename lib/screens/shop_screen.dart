import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config/app_config.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../widgets/app_notice.dart';
import '../widgets/coin_badge.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _claimDaily(BuildContext context) async {
    try {
      final ok = await appState.claimDaily();
      if (!context.mounted) return;
      await showAppNotice(
        context,
        title: ok ? 'Daily reward claimed' : 'Already claimed',
        message: ok ? '+${AppConfig.dailyRewardCoins} coins added to your balance.' : 'Come back tomorrow for your next daily reward.',
        icon: ok ? Icons.card_giftcard_rounded : Icons.schedule_rounded,
        accent: ok ? Colors.greenAccent : Colors.orangeAccent,
      );
    } catch (_) {
      if (!context.mounted) return;
      await showAppNotice(
        context,
        title: 'Reward unavailable',
        message: 'Check your connection and try again.',
        icon: Icons.error_outline_rounded,
        accent: Colors.redAccent,
      );
    }
  }

  Future<void> _watchAd(BuildContext context) async {
    final result = await adService.showRewarded();
    if (!context.mounted) return;
    switch (result) {
      case RewardedAdResult.rewarded:
        await showAppNotice(
          context,
          title: 'Reward added',
          message: '+${AppConfig.rewardedAdCoins} coins added to your balance.',
          icon: Icons.monetization_on_rounded,
          accent: const Color(0xFFFFD54F),
        );
      case RewardedAdResult.dailyLimit:
        await showAppNotice(
          context,
          title: 'Daily limit reached',
          message: 'You can earn coins from rewarded ads ${AppConfig.rewardedAdsPerDay} times per day.',
          icon: Icons.schedule_rounded,
          accent: Colors.orangeAccent,
        );
      case RewardedAdResult.notEarned:
        await showAppNotice(
          context,
          title: 'Reward not completed',
          message: 'Finish the rewarded ad to receive coins.',
          icon: Icons.play_circle_outline_rounded,
          accent: Colors.orangeAccent,
        );
      case RewardedAdResult.unavailable:
        await showAppNotice(
          context,
          title: 'Ad unavailable',
          message: 'No rewarded ad is ready right now. Please try again shortly.',
          icon: Icons.wifi_tethering_error_rounded,
          accent: Colors.orangeAccent,
        );
    }
  }

  Future<void> _buy(BuildContext context, String productId) async {
    final ok = await purchaseService.buy(productId);
    if (!context.mounted) return;
    if (!ok) {
      await showAppNotice(
        context,
        title: 'Coin pack unavailable',
        message: 'This pack is not available from Google Play yet. Please try again later.',
        icon: Icons.shopping_bag_outlined,
        accent: Colors.orangeAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: Listenable.merge([appState, adService, purchaseService]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              const Row(
                children: [
                  Expanded(child: Text('Coins & Rewards', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                  CoinBadge(),
                ],
              ),
              const SizedBox(height: 18),
              _RewardCard(
                icon: Icons.card_giftcard_rounded,
                title: 'Daily Reward',
                subtitle: appState.canClaimDaily ? '+${AppConfig.dailyRewardCoins} coins available today' : 'Already claimed today',
                button: appState.canClaimDaily ? 'Claim' : 'Claimed',
                onTap: appState.canClaimDaily ? () => _claimDaily(context) : null,
              ),
              const SizedBox(height: 12),
              _RewardCard(
                icon: Icons.play_circle_fill_rounded,
                title: 'Rewarded Ad',
                subtitle: '+${AppConfig.rewardedAdCoins} coins • ${appState.adsWatchedToday}/${AppConfig.rewardedAdsPerDay} watched today',
                button: appState.adsWatchedToday >= AppConfig.rewardedAdsPerDay ? 'Daily limit' : (adService.loading ? 'Loading…' : 'Watch'),
                onTap: appState.adsWatchedToday >= AppConfig.rewardedAdsPerDay ? null : () => _watchAd(context),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Text('Buy coins', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                  if (purchaseService.loading)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Coin packs are processed securely by Google Play.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              ...AppConfig.coinProducts.entries.map((entry) {
                final product = purchaseService.products[entry.key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.monetization_on_rounded)),
                      title: Text('${entry.value} Coins', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(product?.description.isNotEmpty == true ? product!.description : 'Use coins for premium player cards.'),
                      trailing: FilledButton.tonal(
                        onPressed: product == null ? null : () => _buy(context, entry.key),
                        child: Text(product?.price ?? 'Unavailable'),
                      ),
                    ),
                  ),
                );
              }),
              if (!purchaseService.available) ...[
                const SizedBox(height: 4),
                const Text('Coin packs are temporarily unavailable. Please try again later.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              const Text('Coin history', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (appState.coinHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No coin activity yet.', style: TextStyle(color: Colors.white54)),
                )
              else
                ...appState.coinHistory.take(12).map((h) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(h.amount >= 0 ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded),
                      title: Text(h.label),
                      trailing: Text(
                        '${h.amount >= 0 ? '+' : ''}${h.amount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: h.amount >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.icon, required this.title, required this.subtitle, required this.button, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(onPressed: onTap, child: Text(button)),
          ],
        ),
      ),
    );
  }
}
