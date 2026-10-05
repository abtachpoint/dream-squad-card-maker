import 'package:flutter/material.dart';
import '../widgets/coin_badge.dart';
import '../app_state.dart';
import 'efootball_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onTabRequested});
  final ValueChanged<int> onTabRequested;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Row(
            children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Dream Squad', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text('Card Maker', style: TextStyle(color: Colors.white54))])),
              GestureDetector(onTap: () => onTabRequested(3), child: const CoinBadge()),
            ],
          ),
          const SizedBox(height: 22),
          _GameCard(
            title: 'eFootball',
            subtitle: 'Card maker + squad builder',
            image: 'assets/images/efootball_cover.webp',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EfootballHubScreen())),
          ),
          const SizedBox(height: 14),
          const Row(children: [Expanded(child: _ComingGame(title: 'EA / FC')), SizedBox(width: 12), Expanded(child: _ComingGame(title: 'DLS'))]),
          const SizedBox(height: 24),
          const Text('Quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Quick(icon: Icons.card_giftcard_rounded, label: 'Daily reward', onTap: () async {
                final ok = await appState.claimDaily();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '+10 coins added' : 'Daily reward already claimed')));
              })),
              const SizedBox(width: 10),
              Expanded(child: _Quick(icon: Icons.play_circle_fill_rounded, label: 'Watch ad', onTap: () => onTabRequested(3))),
              const SizedBox(width: 10),
              Expanded(child: _Quick(icon: Icons.collections_bookmark_rounded, label: 'My cards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EfootballHubScreen(openMyCards: true))))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.title, required this.subtitle, required this.image, required this.onTap});
  final String title, subtitle, image;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover, alignment: Alignment.topCenter),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xE6000000)]))),
              Positioned(left: 18, right: 18, bottom: 16, child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: Colors.white70))])), const Icon(Icons.arrow_forward_rounded)])),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingGame extends StatelessWidget {
  const _ComingGame({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF171923), Color(0xFF0F1016)]), border: Border.all(color: Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Text('COMING SOON', style: TextStyle(fontSize: 11, color: Colors.white38))]),
      );
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 26), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
        ),
      );
}
