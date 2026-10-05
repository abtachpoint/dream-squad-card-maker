import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../models/card_project.dart';
import '../models/squad_project.dart';
import '../widgets/app_notice.dart';
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
  final managerName = TextEditingController();
  final picker = ImagePicker();

  String formation = '4-3-3';
  int fieldStyle = 0;
  String? customBackground;
  String? teamLogo;
  String? managerPhoto;
  int? captainIndex;
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
    managerName.dispose();
    super.dispose();
  }

  Future<String?> _pickAndCrop({bool wide = false}) async {
    final selected = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (selected == null) return null;
    try {
      final result = await ImageCropper().cropImage(
        sourcePath: selected.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        aspectRatio: wide ? const CropAspectRatio(ratioX: 3, ratioY: 4) : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust image',
            toolbarColor: const Color(0xFF090A0E),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF090A0E),
            activeControlsWidgetColor: const Color(0xFF7757FF),
            lockAspectRatio: false,
          ),
        ],
      );
      return result?.path ?? selected.path;
    } catch (_) {
      return selected.path;
    }
  }

  Future<CardProject?> _pickCard() async {
    if (appState.cards.isEmpty) {
      await showAppNotice(
        context,
        title: 'No player cards yet',
        message: 'Create at least one player card before adding players to a squad.',
        icon: Icons.style_outlined,
        accent: Colors.orangeAccent,
      );
      return null;
    }
    return showModalBottomSheet<CardProject>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .60,
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
                    final file = File(c.previewPath);
                    return InkWell(
                      onTap: () => Navigator.pop(context, c),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: file.existsSync() ? Image.file(file, fit: BoxFit.cover, width: double.infinity) : Container(color: Colors.white10),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(c.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseCard(int slotIndex) async {
    final picked = await _pickCard();
    if (picked != null && mounted) setState(() => slots[slotIndex] = picked);
  }

  Future<void> _slotActions(int index) async {
    if (slots[index] == null) {
      await _chooseCard(index);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.swap_horiz_rounded), title: const Text('Replace player'), onTap: () => Navigator.pop(context, 'replace')),
            ListTile(leading: const Icon(Icons.verified_rounded), title: Text(captainIndex == index ? 'Remove captain' : 'Make captain'), onTap: () => Navigator.pop(context, 'captain')),
            ListTile(leading: const Icon(Icons.close_rounded), title: const Text('Clear slot'), onTap: () => Navigator.pop(context, 'clear')),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'replace') {
      await _chooseCard(index);
    } else if (action == 'captain') {
      setState(() => captainIndex = captainIndex == index ? null : index);
    } else if (action == 'clear') {
      setState(() {
        slots[index] = null;
        if (captainIndex == index) captainIndex = null;
      });
    }
  }

  void _swap(int from, int to) {
    if (from == to) return;
    setState(() {
      final temp = slots[from];
      slots[from] = slots[to];
      slots[to] = temp;
      if (captainIndex == from) {
        captainIndex = to;
      } else if (captainIndex == to) {
        captainIndex = from;
      }
    });
  }

  Future<Uint8List> _capture() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Could not render squad image.');
    return data.buffer.asUint8List();
  }

  Future<void> _saveSquad() async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final bytes = await _capture();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/squad_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);
      final title = teamName.text.trim().isEmpty ? 'My Dream Squad' : teamName.text.trim();
      await appState.addSquad(SquadProject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: title,
        formation: formation,
        previewPath: file.path,
      ));
      if (mounted) {
        await showAppNotice(context, title: 'Squad saved', message: 'Saved to My Squads.', icon: Icons.check_circle_rounded, accent: Colors.greenAccent);
      }
    } catch (_) {
      if (mounted) {
        await showAppNotice(context, title: 'Couldn’t save squad', message: 'Please try again.', icon: Icons.error_outline_rounded, accent: Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _export() async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final bytes = await _capture();
      await galleryChannel.invokeMethod('saveImage', {
        'bytes': bytes,
        'fileName': 'DreamSquad_Lineup_${DateTime.now().millisecondsSinceEpoch}.png',
      });
      if (mounted) {
        await showAppNotice(context, title: 'Squad exported', message: 'Saved to Pictures/Dream Squad Card Maker.', icon: Icons.check_circle_rounded, accent: Colors.greenAccent);
      }
    } catch (_) {
      if (mounted) {
        await showAppNotice(context, title: 'Export failed', message: 'Couldn’t save the squad image. Please try again.', icon: Icons.error_outline_rounded, accent: Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget _playerSlot(int index, Alignment alignment) {
    final card = slots[index];
    final core = GestureDetector(
      onTap: () => _slotActions(index),
      child: SizedBox(
        width: 58,
        height: 78,
        child: card == null
            ? Container(
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white38)),
                child: const Icon(Icons.add_rounded, color: Colors.white70),
              )
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: File(card.previewPath).existsSync() ? Image.file(File(card.previewPath), fit: BoxFit.cover) : Container(color: Colors.white10),
                    ),
                  ),
                  if (captainIndex == index)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD54F)),
                        child: const Text('C', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                ],
              ),
      ),
    );

    return Align(
      alignment: alignment,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => _swap(details.data, index),
        builder: (context, candidates, rejected) {
          final highlighted = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: highlighted ? BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white70, width: 2)) : null,
            child: card == null
                ? core
                : LongPressDraggable<int>(
                    data: index,
                    feedback: Material(color: Colors.transparent, child: Opacity(opacity: .88, child: SizedBox(width: 58, height: 78, child: Image.file(File(card.previewPath), fit: BoxFit.cover)))),
                    childWhenDragging: Opacity(opacity: .30, child: core),
                    child: core,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final alignments = formations[formation]!;
    final customBgFile = customBackground == null ? null : File(customBackground!);
    final logoFile = teamLogo == null ? null : File(teamLogo!);
    final managerFile = managerPhoto == null ? null : File(managerPhoto!);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          if (widget.embedded)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(children: [Expanded(child: Text('Squad Builder', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), CoinBadge()]),
            ),
          RepaintBoundary(
            key: previewKey,
            child: AspectRatio(
              aspectRatio: .72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (customBgFile != null && customBgFile.existsSync())
                      Image.file(customBgFile, fit: BoxFit.cover)
                    else
                      DecoratedBox(
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
                      ),
                    DecoratedBox(decoration: BoxDecoration(color: customBgFile != null ? Colors.black.withValues(alpha: .20) : Colors.transparent)),
                    CustomPaint(painter: _PitchPainter()),
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (logoFile != null && logoFile.existsSync()) ...[
                            ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.file(logoFile, width: 36, height: 36, fit: BoxFit.contain)),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              teamName.text.trim().isEmpty ? 'MY DREAM SQUAD' : teamName.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, shadows: [Shadow(blurRadius: 6, color: Colors.black)]),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                    ...List.generate(11, (i) => _playerSlot(i, alignments[i])),
                    if (managerName.text.trim().isNotEmpty || (managerFile != null && managerFile.existsSync()))
                      Positioned(
                        left: 10,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (managerFile != null && managerFile.existsSync()) ...[
                                ClipOval(child: Image.file(managerFile, width: 24, height: 24, fit: BoxFit.cover)),
                                const SizedBox(width: 6),
                              ],
                              Text(managerName.text.trim().isEmpty ? 'Manager' : managerName.text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: teamName, onChanged: (_) => setState(() {}), maxLength: 30, decoration: const InputDecoration(labelText: 'Team name', counterText: '')),
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
            onSelectionChanged: (v) => setState(() {
              fieldStyle = v.first;
              customBackground = null;
            }),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await _pickAndCrop(wide: true);
              if (p != null) setState(() => customBackground = p);
            },
            icon: const Icon(Icons.wallpaper_rounded),
            label: Text(customBackground == null ? 'Upload custom background' : 'Replace custom background'),
          ),
          const SizedBox(height: 16),
          const Text('Team info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final p = await _pickAndCrop();
                    if (p != null) setState(() => teamLogo = p);
                  },
                  icon: const Icon(Icons.shield_outlined),
                  label: Text(teamLogo == null ? 'Upload club logo' : 'Replace club logo'),
                ),
              ),
              if (teamLogo != null) IconButton(onPressed: () => setState(() => teamLogo = null), icon: const Icon(Icons.close_rounded), tooltip: 'Remove logo'),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: managerName, onChanged: (_) => setState(() {}), maxLength: 28, decoration: const InputDecoration(labelText: 'Manager name (optional)', counterText: '')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final p = await _pickAndCrop();
                    if (p != null) setState(() => managerPhoto = p);
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(managerPhoto == null ? 'Manager photo (optional)' : 'Replace manager photo'),
                ),
              ),
              if (managerPhoto != null) IconButton(onPressed: () => setState(() => managerPhoto = null), icon: const Icon(Icons.close_rounded), tooltip: 'Remove manager photo'),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tap a slot to add or manage a player. Long-press and drag a filled card to swap positions.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SizedBox(height: 52, child: FilledButton.tonalIcon(onPressed: exporting ? null : _saveSquad, icon: const Icon(Icons.bookmark_add_rounded), label: const Text('Save Squad')))),
              const SizedBox(width: 10),
              Expanded(child: SizedBox(height: 52, child: FilledButton.icon(onPressed: exporting ? null : _export, icon: const Icon(Icons.download_rounded), label: Text(exporting ? 'Saving…' : 'Export')))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildContent();
    return Scaffold(
      appBar: AppBar(title: const Text('Squad Builder'), actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge()))]),
      body: _buildContent(),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
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
