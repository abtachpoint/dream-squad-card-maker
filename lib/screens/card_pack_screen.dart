import 'package:flutter/material.dart';
import '../data/templates.dart';
import '../models/card_template.dart';
import '../widgets/card_preview.dart';
import '../widgets/coin_badge.dart';
import 'card_editor_screen.dart';

class CardPackScreen extends StatefulWidget {
  const CardPackScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<CardPackScreen> createState() => _CardPackScreenState();
}

class _CardPackScreenState extends State<CardPackScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() { tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Column(
        children: [
          if (widget.embedded) Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 10), child: Row(children: [const Expanded(child: Text('Create Player Card', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), const CoinBadge()])),
          TabBar(controller: tabs, tabs: const [Tab(text: 'FREE'), Tab(text: 'PREMIUM'), Tab(text: 'BIG TIME')]),
          Expanded(child: TabBarView(controller: tabs, children: const [_TemplateGrid(pack: CardPack.free), _TemplateGrid(pack: CardPack.premium), _TemplateGrid(pack: CardPack.bigTime)])),
        ],
      ),
    );
    if (widget.embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Card Packs'), actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge()))]), body: body);
  }
}

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({required this.pack});
  final CardPack pack;
  @override
  Widget build(BuildContext context) {
    final list = cardTemplates.where((e) => e.pack == pack).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .66, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardEditorScreen(template: t))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF12141B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(
              children: [
                Expanded(child: CardPreview(template: t, compact: true)),
                const SizedBox(height: 7),
                Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(t.coinCost == 0 ? 'FREE' : '${t.coinCost} coins', style: TextStyle(fontSize: 11, color: t.coinCost == 0 ? Colors.greenAccent : const Color(0xFFFFD54F), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      },
    );
  }
}
