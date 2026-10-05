import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models/card_project.dart';
import '../widgets/coin_badge.dart';

class SquadBuilderScreen extends StatefulWidget {
  const SquadBuilderScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<SquadBuilderScreen> createState() => _SquadBuilderScreenState();
}

class _SquadBuilderScreenState extends State<SquadBuilderScreen> {
  static const galleryChannel = MethodChannel('com.soikot.dreamsquad/gallery');
  final previewKey = GlobalKey();
  final teamName = TextEditingController(text: 'MY DREAM SQUAD');
  String formation = '4-3-3';
  int fieldStyle = 0;
  final List<CardProject?> slots = List<CardProject?>.filled(11, null);
  bool exporting = false;

  final Map<String, List<Alignment>> formations = const {
    '4-3-3': [
      Alignment(-.72, -.55), Alignment(0, -.68), Alignment(.72, -.55),
      Alignment(-.55, -.05), Alignment(0, .02), Alignment(.55, -.05),
      Alignment(-.78, .50), Alignment(-.28, .43), Alignment(.28, .43), Alignment(.78, .50),
      Alignment(0, .82),
    ],
    '4-2-3-1': [
      Alignment(0, -.68),
      Alignment(-.70, -.34), Alignment(0, -.30), Alignment(.70, -.34),
      Alignment(-.35, .05), Alignment(.35, .05),
      Alignment(-.78, .50), Alignment(-.28, .43), Alignment(.28, .43), Alignment(.78, .50),
      Alignment(0, .82),
    ],
    '4-4-2': [
      Alignment(-.32, -.62), Alignment(.32, -.62),
      Alignment(-.75, -.10), Alignment(-.25, .02), Alignment(.25, .02), Alignment(.75, -.10),
      Alignment(-.78, .50), Alignment(-.28, .43), Alignment(.28, .43), Alignment(.78, .50),
      Alignment(0, .82),
    ],
    '3-5-2': [
      Alignment(-.30, -.62), Alignment(.30, -.62),
      Alignment(-.78, -.12), Alignment(-.38, .02), Alignment(0, -.05), Alignment(.38, .02), Alignment(.78, -.12),
      Alignment(-.55, .48), Alignment(0, .40), Alignment(.55, .48),
      Alignment(0, .82),
    ],
    '4-1-2-3': [
      Alignment(-.72, -.55), Alignment(0, -.68), Alignment(.72, -.55),
      Alignment(-.42, -.08), Alignment(.42, -.08), Alignment(0, .22),
      Alignment(-.78, .50), Alignment(-.28, .43), Alignment(.28, .43), Alignment(.78, .50),
      Alignment(0, .82),
    ],
  };

  @override
  void dispose() {
    teamName.dispose();
    super.dispose();
  }

  Future<void> _chooseCard(int slotIndex) async {
    if (appState.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create at least one player card first.')));
      return;
    }
    final picked = await showModalBottomSheet<CardProject>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .58,
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('Choose player card', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .66, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: appState.cards.length,
                  itemBuilder: (_, i) {
                    final c = appState.cards[i];
                    return InkWell(
                      onTap: () => Navigator.pop(context, c),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(c.previewPath), fit: BoxFit.cover, width: double.infinity))),
                        const SizedBox(height: 4),
                        Text(c.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => slots[slotIndex] = picked);
  }

  Future<Uint8List> _capture() async {
    final boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _export() async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final bytes = await _capture();
      await galleryChannel.invokeMethod('saveImage', {'bytes': bytes, 'fileName': 'DreamSquad_Lineup_${DateTime.now().millisecondsSinceEpoch}.png'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Squad exported to Pictures/Dream Squad Card Maker.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed in this environment: $e')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget _buildContent() {
    final alignments = formations[formation]!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          if (widget.embedded)
            const Padding(padding: EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: Text('Squad Builder', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), CoinBadge()])),
          RepaintBoundary(
            key: previewKey,
            child: AspectRatio(
              aspectRatio: .72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: fieldStyle == 0
                          ? const [Color(0xFF0B5B35), Color(0xFF073D2A)]
                          : fieldStyle == 1
                              ? const [Color(0xFF15203C), Color(0xFF09111F)]
                              : const [Color(0xFF311854), Color(0xFF130D25)],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _PitchPainter()),
                      Positioned(top: 12, left: 12, right: 12, child: Text(teamName.text.trim().isEmpty ? 'MY DREAM SQUAD' : teamName.text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, shadows: [Shadow(blurRadius: 6, color: Colors.black)]))),
                      ...List.generate(11, (i) {
                        final a = alignments[i];
                        return Align(
                          alignment: a,
                          child: GestureDetector(
                            onTap: () => _chooseCard(i),
                            onLongPress: () => setState(() => slots[i] = null),
                            child: SizedBox(
                              width: 58,
                              height: 78,
                              child: slots[i] == null
                                  ? Container(
                                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white38)),
                                      child: const Icon(Icons.add_rounded, color: Colors.white70),
                                    )
                                  : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(slots[i]!.previewPath), fit: BoxFit.cover)),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: teamName, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Team name')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: formation,
            decoration: const InputDecoration(labelText: 'Formation'),
            items: formations.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) => setState(() => formation = v ?? formation),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [ButtonSegment(value: 0, label: Text('Green')), ButtonSegment(value: 1, label: Text('Dark')), ButtonSegment(value: 2, label: Text('Purple'))],
            selected: {fieldStyle},
            onSelectionChanged: (v) => setState(() => fieldStyle = v.first),
          ),
          const SizedBox(height: 12),
          const Text('Tap any slot to add/replace a saved card. Long-press a slot to clear it.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(height: 52, child: FilledButton.icon(onPressed: exporting ? null : _export, icon: const Icon(Icons.download_rounded), label: Text(exporting ? 'Exporting...' : 'Export Squad to Device'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildContent();
    return Scaffold(appBar: AppBar(title: const Text('Squad Builder'), actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge()))]), body: _buildContent());
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.4;
    final r = Rect.fromLTWH(size.width * .07, size.height * .08, size.width * .86, size.height * .86);
    canvas.drawRect(r, p);
    canvas.drawLine(Offset(r.left, size.height * .51), Offset(r.right, size.height * .51), p);
    canvas.drawCircle(Offset(size.width / 2, size.height * .51), size.width * .12, p);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, r.top), width: size.width * .42, height: size.height * .16), p);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, r.bottom), width: size.width * .42, height: size.height * .16), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
