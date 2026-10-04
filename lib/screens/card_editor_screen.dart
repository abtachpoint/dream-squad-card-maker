import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../app_state.dart';
import '../models/card_project.dart';
import '../models/card_template.dart';
import '../widgets/card_preview.dart';
import '../widgets/coin_badge.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.template});
  final CardTemplate template;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final picker = ImagePicker();
  final previewKey = GlobalKey();
  final name = TextEditingController(text: 'YOUR NAME');
  final rating = TextEditingController(text: '90');
  String position = 'CF';
  late final List<String?> photos;
  String? logo;
  String? flag;
  String? background;
  bool saving = false;

  static const galleryChannel = MethodChannel('com.soikot.dreamsquad/gallery');
  static const positions = ['CF', 'SS', 'RWF', 'LWF', 'AMF', 'CMF', 'DMF', 'RB', 'LB', 'CB', 'GK'];

  @override
  void initState() {
    super.initState();
    photos = List<String?>.filled(widget.template.photoSlots, null);
  }

  @override
  void dispose() {
    name.dispose();
    rating.dispose();
    super.dispose();
  }

  int get parsedRating => (int.tryParse(rating.text.trim()) ?? 90).clamp(1, 150).toInt();

  Future<String?> _pick() async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    return x?.path;
  }

  Future<void> _pickPhoto(int index) async {
    final p = await _pick();
    if (p != null) setState(() => photos[index] = p);
  }

  void _bgRemovalNotice() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trial build: on-device background-removal hook is reserved for the next build. Upload/crop/placement can be tested now.')));
  }

  Future<Uint8List> _capture() async {
    await Future.delayed(const Duration(milliseconds: 30));
    final boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<String> _saveLocal(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/card_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _saveCard() async {
    if (saving) return;
    FocusScope.of(context).unfocus();
    final cost = widget.template.coinCost;
    if (cost > 0 && appState.coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough coins. You need $cost coins.')));
      return;
    }
    if (cost > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Create this card?'),
          content: Text('This ${widget.template.name} costs $cost coins. Preview/editing is free.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create'))],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => saving = true);
    try {
      final bytes = await _capture();
      final spent = await appState.spend(cost);
      if (!spent) throw Exception('Not enough coins');
      final localPath = await _saveLocal(bytes);
      appState.addCard(CardProject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        template: widget.template,
        playerName: name.text.trim().isEmpty ? 'Player' : name.text.trim(),
        rating: parsedRating,
        position: position,
        previewPath: localPath,
      ));
      try {
        await galleryChannel.invokeMethod('saveImage', {'bytes': bytes, 'fileName': 'DreamSquad_${DateTime.now().millisecondsSinceEpoch}.png'});
      } catch (_) {
        // Local project copy is still saved even if gallery bridge is unavailable.
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Card saved'),
          content: const Text('Saved to My Cards. On Android trial builds it is also exported to Pictures/Dream Squad Card Maker.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save card: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name), actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge()))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: RepaintBoundary(
                key: previewKey,
                child: CardPreview(
                  template: widget.template,
                  playerName: name.text,
                  rating: parsedRating,
                  position: position,
                  photoPaths: photos,
                  logoPath: logo,
                  flagPath: flag,
                  customBackgroundPath: background,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Player info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(controller: name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Player name')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: rating, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Main rating'))),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField<String>(value: position, decoration: const InputDecoration(labelText: 'Position'), items: positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => position = v ?? position))),
          ]),
          const SizedBox(height: 20),
          Row(children: [const Expanded(child: Text('Player photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Text('${widget.template.photoSlots} slot${widget.template.photoSlots == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white54))]),
          const SizedBox(height: 8),
          ...List.generate(widget.template.photoSlots, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(i), icon: const Icon(Icons.photo_library_outlined), label: Text(photos[i] == null ? 'Upload Photo ${i + 1}' : 'Replace Photo ${i + 1}'))),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(onPressed: _bgRemovalNotice, tooltip: 'Auto remove background', icon: const Icon(Icons.auto_fix_high_rounded)),
                ]),
              )),
          const SizedBox(height: 12),
          const Text('Logo & flag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () async { final p = await _pick(); if (p != null) setState(() => logo = p); }, icon: const Icon(Icons.shield_outlined), label: Text(logo == null ? 'Upload club logo' : 'Replace logo'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () async { final p = await _pick(); if (p != null) setState(() => flag = p); }, icon: const Icon(Icons.flag_outlined), label: Text(flag == null ? 'Upload flag' : 'Replace flag'))),
          ]),
          TextButton.icon(onPressed: _bgRemovalNotice, icon: const Icon(Icons.content_cut_rounded), label: const Text('Crop / remove background tools')),
          if (!widget.template.backgroundLocked) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () async { final p = await _pick(); if (p != null) setState(() => background = p); }, icon: const Icon(Icons.wallpaper_rounded), label: Text(background == null ? 'Upload custom card background' : 'Replace background')),
          ] else ...[
            const SizedBox(height: 8),
            const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.lock_rounded), title: Text('Background locked'), subtitle: Text('This template uses its fixed background design.')),
          ],
          if (widget.template.boosterSlots > 0)
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.bolt_rounded), title: Text('${widget.template.boosterSlots} booster slot${widget.template.boosterSlots == 1 ? '' : 's'}'), subtitle: const Text('Booster artwork will be customizable in a later trial build.')),
          const SizedBox(height: 12),
          SizedBox(height: 54, child: FilledButton.icon(onPressed: saving ? null : _saveCard, icon: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_done_rounded), label: Text(widget.template.coinCost == 0 ? 'Save Card • FREE' : 'Save Card • ${widget.template.coinCost} coins'))),
        ],
      ),
    );
  }
}
