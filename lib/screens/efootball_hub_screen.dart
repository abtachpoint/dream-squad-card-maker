import 'package:flutter/material.dart';
import '../widgets/coin_badge.dart';
import 'card_pack_screen.dart';
import 'my_cards_screen.dart';
import 'squad_builder_screen.dart';

class EfootballHubScreen extends StatefulWidget {
  const EfootballHubScreen({super.key, this.openMyCards = false});
  final bool openMyCards;

  @override
  State<EfootballHubScreen> createState() => _EfootballHubScreenState();
}

class _EfootballHubScreenState extends State<EfootballHubScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openMyCards) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsScreen())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eFootball Hub'), actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge()))]),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(22), child: SizedBox(height: 185, child: Stack(fit: StackFit.expand, children: [Image.asset('assets/images/efootball_cover.webp', fit: BoxFit.cover, alignment: Alignment.topCenter), const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD000000)]))), const Positioned(left: 16, bottom: 14, child: Text('Create. Build. Share.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)))]))),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _Action(icon: Icons.add_card_rounded, label: 'Create Player Card', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardPackScreen()))),
              _Action(icon: Icons.collections_bookmark_rounded, label: 'My Cards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsScreen()))),
              _Action(icon: Icons.stadium_rounded, label: 'Squad Builder', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadBuilderScreen()))),
              _Action(icon: Icons.photo_library_rounded, label: 'My Squads', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadBuilderScreen()))),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Packs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Wrap(spacing: 8, runSpacing: 8, children: [Chip(label: Text('Free Pack • 3 designs')), Chip(label: Text('Premium Pack • 5 designs')), Chip(label: Text('Big Time Pack • 6 designs'))]),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))]),
        ),
      );
}
