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
import '../models/card_template.dart';
import '../services/cutout_service.dart';
import '../widgets/app_notice.dart';
import '../widgets/card_preview.dart';
import '../widgets/coin_badge.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.template, this.existingCard});
  final CardTemplate template;
  final CardProject? existingCard;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  static const galleryChannel = MethodChannel('com.soikot.dreamsquad/gallery');
  final picker = ImagePicker();
  final previewKey = GlobalKey();
  late final TextEditingController name;
  late final TextEditingController rating;
  final positions = const ['GK', 'CB', 'LB', 'RB', 'DMF', 'CMF', 'AMF', 'LMF', 'RMF', 'LWF', 'RWF', 'SS', 'CF'];

  late List<String?> photos;
  String position = 'CF';
  String? logo;
  String? flag;
  String? background;
  bool saving = false;
  final Set<String> processing = {};

  int get parsedRating => (int.tryParse(rating.text) ?? 90).clamp(1, 999);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCard;
    name = TextEditingController(text: existing?.playerName ?? 'YOUR NAME');
    rating = TextEditingController(text: '${existing?.rating ?? 90}');
    position = existing?.position ?? 'CF';
    photos = List<String?>.generate(
      widget.template.photoSlots,
      (i) => existing != null && i < existing.photoPaths.length ? existing.photoPaths[i] : null,
    );
    logo = existing?.logoPath;
    flag = existing?.flagPath;
    background = existing?.customBackgroundPath;
    cutoutService.warmUp();
  }

  @override
  void dispose() {
    name.dispose();
    rating.dispose();
    super.dispose();
  }

  Future<String?> _pickImage({bool crop = true}) async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return null;
    if (!crop) return picked.path;
    return _crop(picked.path);
  }

  Future<String?> _crop(String sourcePath) async {
    try {
      final result = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust image',
            toolbarColor: const Color(0xFF090A0E),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF090A0E),
            activeControlsWidgetColor: const Color(0xFF7757FF),
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
        ],
      );
      return result?.path ?? sourcePath;
    } catch (_) {
      return sourcePath;
    }
  }

  Future<String?> _removeBackground(String? sourcePath, String key) async {
    if (sourcePath == null || processing.contains(key)) return null;
    setState(() => processing.add(key));
    try {
      final result = await cutoutService.removeBackground(sourcePath);
      if (!mounted) return result;
      await showAppNotice(
        context,
        title: 'Background removed',
        message: 'The transparent cutout is ready. Use Adjust if you want to crop or reposition it.',
        icon: Icons.auto_fix_high_rounded,
        accent: Colors.greenAccent,
      );
      return result;
    } catch (e) {
      if (!mounted) return null;
      await showAppNotice(
        context,
        title: 'Couldn’t remove background',
        message: e is CutoutServiceException ? e.message : 'Try a clearer image and check your internet connection.',
        icon: Icons.warning_amber_rounded,
        accent: Colors.orangeAccent,
      );
      return null;
    } finally {
      if (mounted) setState(() => processing.remove(key));
    }
  }

  Future<Uint8List> _capture() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Could not render card image.');
    return data.buffer.asUint8List();
  }

  Future<String> _saveProjectImage(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/card_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _saveCard() async {
    if (saving) return;
    FocusScope.of(context).unfocus();
    final editing = widget.existingCard != null;
    final cost = editing ? 0 : widget.template.coinCost;
    if (cost > 0 && appState.coins < cost) {
      await showAppNotice(
        context,
        title: 'Not enough coins',
        message: 'You need $cost coins to create this card.',
        icon: Icons.monetization_on_rounded,
        accent: const Color(0xFFFFD54F),
      );
      return;
    }

    if (cost > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create this card?'),
          content: Text('This ${widget.template.name} costs $cost coins. Preview and editing are free.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => saving = true);
    String? localPath;
    try {
      final bytes = await _capture();
      localPath = await _saveProjectImage(bytes);
      final spent = await appState.spend(cost, label: widget.template.name);
      if (!spent) {
        try {
          await File(localPath).delete();
        } catch (_) {}
        if (!mounted) return;
        await showAppNotice(
          context,
          title: 'Not enough coins',
          message: 'Your balance changed. Get more coins and try again.',
          icon: Icons.monetization_on_rounded,
          accent: const Color(0xFFFFD54F),
        );
        return;
      }

      final updatedCard = CardProject(
        id: widget.existingCard?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        template: widget.template,
        playerName: name.text.trim().isEmpty ? 'Player' : name.text.trim(),
        rating: parsedRating,
        position: position,
        previewPath: localPath,
        photoPaths: List<String?>.from(photos),
        logoPath: logo,
        flagPath: flag,
        customBackgroundPath: background,
      );
      if (editing) {
        await appState.updateCard(updatedCard);
      } else {
        await appState.addCard(updatedCard);
      }

      try {
        await galleryChannel.invokeMethod('saveImage', {
          'bytes': bytes,
          'fileName': 'DreamSquad_${DateTime.now().millisecondsSinceEpoch}.png',
        });
      } catch (_) {
        // My Cards copy is already saved even if gallery export fails.
      }

      if (!mounted) return;
      await showAppNotice(
        context,
        title: editing ? 'Card updated' : 'Card saved',
        message: editing ? 'Your saved card has been updated and exported.' : 'Saved to My Cards and exported to your device.',
        icon: Icons.check_circle_rounded,
        accent: Colors.greenAccent,
      );
    } catch (_) {
      if (localPath != null) {
        try {
          await File(localPath).delete();
        } catch (_) {}
      }
      if (mounted) {
        await showAppNotice(
          context,
          title: 'Couldn’t save card',
          message: 'Please try again.',
          icon: Icons.error_outline_rounded,
          accent: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _imageRow({
    required String label,
    required String keyName,
    required String? value,
    required IconData uploadIcon,
    required Future<void> Function(String?) onChanged,
  }) {
    final busy = processing.contains(keyName);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final p = await _pickImage();
                    if (p != null) await onChanged(p);
                  },
            icon: Icon(uploadIcon),
            label: Text(value == null ? 'Upload $label' : 'Replace $label'),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: value == null || busy
              ? null
              : () async {
                  final p = await _crop(value);
                  if (p != null) await onChanged(p);
                },
          tooltip: 'Adjust / crop',
          icon: const Icon(Icons.crop_rounded),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          onPressed: value == null || busy
              ? null
              : () async {
                  final p = await _removeBackground(value, keyName);
                  if (p != null) await onChanged(p);
                },
          tooltip: 'Remove background',
          icon: busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_fix_high_rounded),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge()))],
      ),
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
          TextField(controller: name, onChanged: (_) => setState(() {}), maxLength: 24, decoration: const InputDecoration(labelText: 'Player name', counterText: '')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: rating,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Main rating'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: position,
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => position = v ?? position),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Text('Player photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              Text('${widget.template.photoSlots} slot${widget.template.photoSlots == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            widget.template.photoSlots,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _imageRow(
                label: 'Photo ${i + 1}',
                keyName: 'photo$i',
                value: photos[i],
                uploadIcon: Icons.photo_library_outlined,
                onChanged: (p) async => setState(() => photos[i] = p),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Club logo & flag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _imageRow(
            label: 'Club Logo',
            keyName: 'logo',
            value: logo,
            uploadIcon: Icons.shield_outlined,
            onChanged: (p) async => setState(() => logo = p),
          ),
          const SizedBox(height: 8),
          _imageRow(
            label: 'Flag',
            keyName: 'flag',
            value: flag,
            uploadIcon: Icons.flag_outlined,
            onChanged: (p) async => setState(() => flag = p),
          ),
          if (!widget.template.backgroundLocked) ...[
            const SizedBox(height: 16),
            const Text('Card background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final p = await _pickImage(crop: false);
                      if (p != null) setState(() => background = p);
                    },
                    icon: const Icon(Icons.wallpaper_rounded),
                    label: Text(background == null ? 'Upload background' : 'Replace background'),
                  ),
                ),
                if (background != null) ...[
                  const SizedBox(width: 6),
                  IconButton.filledTonal(onPressed: () => setState(() => background = null), tooltip: 'Use default background', icon: const Icon(Icons.restart_alt_rounded)),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_rounded),
              title: Text('Fixed card background'),
              subtitle: Text('This design keeps its built-in background.'),
            ),
          ],
          if (widget.template.boosterSlots > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt_rounded),
              title: Text('${widget.template.boosterSlots} active booster${widget.template.boosterSlots == 1 ? '' : 's'}'),
              subtitle: const Text('Booster badges are part of this card design.'),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: saving ? null : _saveCard,
              icon: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_done_rounded),
              label: Text(widget.existingCard != null ? 'Update Card' : (widget.template.coinCost == 0 ? 'Save Card • FREE' : 'Save Card • ${widget.template.coinCost} coins')),
            ),
          ),
        ],
      ),
    );
  }
}
