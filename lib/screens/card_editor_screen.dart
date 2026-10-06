import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../models/card_project.dart';
import '../models/card_template.dart';
import '../models/element_transform.dart';
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
  late List<ElementTransform> photoTransforms;
  late List<double> photoOpacities;
  late List<int> photoOrder;
  ElementTransform nameTransform = const ElementTransform();
  ElementTransform ratingTransform = const ElementTransform();

  String position = 'CF';
  String? logo;
  String? flag;
  String? background;
  bool saving = false;
  final Set<String> processing = {};

  final List<_EditorSnapshot> undoStack = [];
  final List<_EditorSnapshot> redoStack = [];
  Timer? _draftTimer;
  bool _draftRestored = false;

  int get parsedRating => (int.tryParse(rating.text) ?? 90).clamp(1, 999).toInt();
  String get _draftKey => 'cardDraft_${appState.firebaseUser?.uid ?? 'local'}_${widget.existingCard?.id ?? widget.template.id}';

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
    photoTransforms = List<ElementTransform>.generate(
      widget.template.photoSlots,
      (i) => existing != null && i < existing.photoTransforms.length ? existing.photoTransforms[i] : const ElementTransform(),
    );
    photoOpacities = List<double>.generate(
      widget.template.photoSlots,
      (i) => existing != null && i < existing.photoOpacities.length ? existing.photoOpacities[i].clamp(.15, 1.0).toDouble() : 1.0,
    );
    photoOrder = existing != null && existing.photoOrder.length == widget.template.photoSlots
        ? List<int>.from(existing.photoOrder)
        : List<int>.generate(widget.template.photoSlots, (i) => i);
    nameTransform = existing?.nameTransform ?? const ElementTransform();
    ratingTransform = existing?.ratingTransform ?? const ElementTransform();
    logo = existing?.logoPath;
    flag = existing?.flagPath;
    background = existing?.customBackgroundPath;

    if (existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    name.dispose();
    rating.dispose();
    super.dispose();
  }

  _EditorSnapshot _snapshot() => _EditorSnapshot(
        playerName: name.text,
        rating: rating.text,
        position: position,
        photos: List<String?>.from(photos),
        photoTransforms: List<ElementTransform>.from(photoTransforms),
        photoOpacities: List<double>.from(photoOpacities),
        photoOrder: List<int>.from(photoOrder),
        logo: logo,
        flag: flag,
        background: background,
        nameTransform: nameTransform,
        ratingTransform: ratingTransform,
      );

  void _beginChange() {
    final current = _snapshot();
    if (undoStack.isEmpty || undoStack.last.signature != current.signature) {
      undoStack.add(current);
      if (undoStack.length > 40) undoStack.removeAt(0);
    }
    redoStack.clear();
  }

  void _restoreSnapshot(_EditorSnapshot snap) {
    name.text = snap.playerName;
    rating.text = snap.rating;
    position = snap.position;
    photos = List<String?>.from(snap.photos);
    photoTransforms = List<ElementTransform>.from(snap.photoTransforms);
    photoOpacities = List<double>.from(snap.photoOpacities);
    photoOrder = List<int>.from(snap.photoOrder);
    logo = snap.logo;
    flag = snap.flag;
    background = snap.background;
    nameTransform = snap.nameTransform;
    ratingTransform = snap.ratingTransform;
    setState(() {});
    _scheduleDraftSave();
  }

  void _undo() {
    if (undoStack.isEmpty) return;
    redoStack.add(_snapshot());
    _restoreSnapshot(undoStack.removeLast());
  }

  void _redo() {
    if (redoStack.isEmpty) return;
    undoStack.add(_snapshot());
    _restoreSnapshot(redoStack.removeLast());
  }

  void _scheduleDraftSave() {
    if (widget.existingCard != null || !_draftRestored) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 300), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (widget.existingCard != null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'playerName': name.text,
      'rating': rating.text,
      'position': position,
      'photos': photos,
      'photoTransforms': photoTransforms.map((e) => e.toJson()).toList(),
      'photoOpacities': photoOpacities,
      'photoOrder': photoOrder,
      'logo': logo,
      'flag': flag,
      'background': background,
      'nameTransform': nameTransform.toJson(),
      'ratingTransform': ratingTransform.toJson(),
    };
    await prefs.setString(_draftKey, jsonEncode(data));
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    _draftRestored = true;
    if (raw == null || !mounted) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final draftPhotos = data['photos'] as List<dynamic>?;
      final draftTransforms = data['photoTransforms'] as List<dynamic>?;
      final draftOpacity = data['photoOpacities'] as List<dynamic>?;
      final draftOrder = data['photoOrder'] as List<dynamic>?;
      name.text = data['playerName'] as String? ?? name.text;
      rating.text = data['rating'] as String? ?? rating.text;
      position = data['position'] as String? ?? position;
      if (draftPhotos != null) {
        photos = List<String?>.generate(widget.template.photoSlots, (i) => i < draftPhotos.length ? draftPhotos[i] as String? : null);
      }
      if (draftTransforms != null) {
        photoTransforms = List<ElementTransform>.generate(
          widget.template.photoSlots,
          (i) => i < draftTransforms.length ? ElementTransform.fromJson(draftTransforms[i]) : const ElementTransform(),
        );
      }
      if (draftOpacity != null) {
        photoOpacities = List<double>.generate(
          widget.template.photoSlots,
          (i) => i < draftOpacity.length ? ((draftOpacity[i] as num?)?.toDouble() ?? 1).clamp(.15, 1.0).toDouble() : 1.0,
        );
      }
      if (draftOrder != null && draftOrder.length == widget.template.photoSlots) {
        photoOrder = draftOrder.map((e) => (e as num?)?.toInt() ?? 0).toList();
      }
      logo = data['logo'] as String?;
      flag = data['flag'] as String?;
      background = data['background'] as String?;
      nameTransform = ElementTransform.fromJson(data['nameTransform']);
      ratingTransform = ElementTransform.fromJson(data['ratingTransform']);
      setState(() {});
      if (mounted) {
        await showAppNotice(
          context,
          title: 'Draft restored',
          message: 'Your unfinished card edits were restored automatically.',
          icon: Icons.restore_rounded,
          accent: Colors.lightBlueAccent,
        );
      }
    } catch (_) {
      await prefs.remove(_draftKey);
    }
  }

  Future<void> _clearDraft() async {
    _draftTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<String?> _pickImage({bool crop = true}) async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return null;
    final path = crop ? await _crop(picked.path) : picked.path;
    if (path != null && mounted && !path.toLowerCase().endsWith('.png')) {
      await showAppNotice(
        context,
        title: 'PNG works best',
        message: 'For the cleanest card result, use a PNG image with the background already removed.',
        icon: Icons.info_outline_rounded,
        accent: Colors.lightBlueAccent,
      );
    }
    return path;
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
      final result = await cutoutService.removeBackground(
        sourcePath,
        person: key.startsWith('photo'),
      );
      if (!mounted) return result;
      await showAppNotice(
        context,
        title: 'Background removed',
        message: 'The transparent cutout is ready. Drag or pinch it directly on the card to adjust.',
        icon: Icons.auto_fix_high_rounded,
        accent: Colors.greenAccent,
      );
      return result;
    } catch (e) {
      if (!mounted) return null;
      await showAppNotice(
        context,
        title: 'Couldn’t remove background',
        message: e is CutoutServiceException ? e.message : 'Try a clearer image or crop it more tightly first.',
        icon: Icons.warning_amber_rounded,
        accent: Colors.orangeAccent,
      );
      return null;
    } finally {
      if (mounted) setState(() => processing.remove(key));
    }
  }

  Future<Uint8List> _capture() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4);
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
        photoTransforms: List<ElementTransform>.from(photoTransforms),
        photoOpacities: List<double>.from(photoOpacities),
        photoOrder: List<int>.from(photoOrder),
        nameTransform: nameTransform,
        ratingTransform: ratingTransform,
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
      } catch (_) {}

      await _clearDraft();
      if (!mounted) return;
      await showAppNotice(
        context,
        title: editing ? 'Card updated' : 'Card saved',
        message: editing ? 'Your saved card has been updated and exported.' : 'Saved to My Cards and exported in high quality.',
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

  void _moveLayer(int index, {required bool front}) {
    _beginChange();
    setState(() {
      photoOrder.remove(index);
      if (front) {
        photoOrder.add(index);
      } else {
        photoOrder.insert(0, index);
      }
    });
    _scheduleDraftSave();
  }

  void _resetPhotoTransform(int index) {
    _beginChange();
    setState(() => photoTransforms[index] = const ElementTransform());
    _scheduleDraftSave();
  }

  Widget _imageRow({
    required String label,
    required String keyName,
    required String? value,
    required IconData uploadIcon,
    required Future<void> Function(String?) onChanged,
    required VoidCallback onRemoved,
    int? photoIndex,
  }) {
    final busy = processing.contains(keyName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final p = await _pickImage();
                        if (p != null) {
                          _beginChange();
                          await onChanged(p);
                          _scheduleDraftSave();
                        }
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
                      if (p != null) {
                        _beginChange();
                        await onChanged(p);
                        _scheduleDraftSave();
                      }
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
                      if (p != null) {
                        _beginChange();
                        await onChanged(p);
                        _scheduleDraftSave();
                      }
                    },
              tooltip: 'Remove background',
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_fix_high_rounded),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              onPressed: value == null || busy
                  ? null
                  : () {
                      _beginChange();
                      onRemoved();
                      _scheduleDraftSave();
                    },
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        if (photoIndex != null && value != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Text('Opacity', style: TextStyle(fontSize: 11, color: Colors.white54)),
              Expanded(
                child: Slider(
                  min: .15,
                  max: 1,
                  divisions: 17,
                  value: photoOpacities[photoIndex],
                  onChangeStart: (_) => _beginChange(),
                  onChanged: (v) {
                    setState(() => photoOpacities[photoIndex] = v);
                    _scheduleDraftSave();
                  },
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Layer controls',
                onSelected: (value) {
                  if (value == 'front') _moveLayer(photoIndex, front: true);
                  if (value == 'back') _moveLayer(photoIndex, front: false);
                  if (value == 'reset') _resetPhotoTransform(photoIndex);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'front', child: Text('Bring to front')),
                  PopupMenuItem(value: 'back', child: Text('Send to back')),
                  PopupMenuItem(value: 'reset', child: Text('Reset position / zoom')),
                ],
                icon: const Icon(Icons.layers_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _showFullPreview() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Card Preview'),
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: CardPreview(
                  template: widget.template,
                  playerName: name.text,
                  rating: parsedRating,
                  position: position,
                  photoPaths: photos,
                  photoTransforms: photoTransforms,
                  photoOpacities: photoOpacities,
                  photoOrder: photoOrder,
                  logoPath: logo,
                  flagPath: flag,
                  customBackgroundPath: background,
                  nameTransform: nameTransform,
                  ratingTransform: ratingTransform,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(onPressed: undoStack.isEmpty ? null : _undo, tooltip: 'Undo', icon: const Icon(Icons.undo_rounded)),
          IconButton(onPressed: redoStack.isEmpty ? null : _redo, tooltip: 'Redo', icon: const Icon(Icons.redo_rounded)),
          IconButton(onPressed: _showFullPreview, tooltip: 'Full-screen preview', icon: const Icon(Icons.fullscreen_rounded)),
          const Padding(padding: EdgeInsets.only(right: 12), child: Center(child: CoinBadge())),
        ],
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
                  photoTransforms: photoTransforms,
                  photoOpacities: photoOpacities,
                  photoOrder: photoOrder,
                  logoPath: logo,
                  flagPath: flag,
                  customBackgroundPath: background,
                  nameTransform: nameTransform,
                  ratingTransform: ratingTransform,
                  interactive: true,
                  onGestureStart: _beginChange,
                  onPhotoTransformChanged: (index, value) {
                    setState(() => photoTransforms[index] = value);
                    _scheduleDraftSave();
                  },
                  onNameTransformChanged: (value) {
                    setState(() => nameTransform = value);
                    _scheduleDraftSave();
                  },
                  onRatingTransformChanged: (value) {
                    setState(() => ratingTransform = value);
                    _scheduleDraftSave();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Tip: drag photos or text with one finger. Pinch with two fingers to resize. Elements snap to center when close.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 18),
          const Text('Player info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(
            controller: name,
            onTap: _beginChange,
            onChanged: (_) {
              setState(() {});
              _scheduleDraftSave();
            },
            maxLength: 24,
            decoration: const InputDecoration(labelText: 'Player name', counterText: ''),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: rating,
                  onTap: _beginChange,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  onChanged: (_) {
                    setState(() {});
                    _scheduleDraftSave();
                  },
                  decoration: const InputDecoration(labelText: 'Main rating'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: position,
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    _beginChange();
                    setState(() => position = v);
                    _scheduleDraftSave();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _beginChange();
                    setState(() => nameTransform = const ElementTransform());
                    _scheduleDraftSave();
                  },
                  icon: const Icon(Icons.text_fields_rounded),
                  label: const Text('Reset name position'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _beginChange();
                    setState(() => ratingTransform = const ElementTransform());
                    _scheduleDraftSave();
                  },
                  icon: const Icon(Icons.numbers_rounded),
                  label: const Text('Reset rating position'),
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
          const SizedBox(height: 5),
          const Text(
            'Upload PNG (background removed) photo for best result.',
            style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            widget.template.photoSlots,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _imageRow(
                label: 'Photo ${i + 1}',
                keyName: 'photo$i',
                value: photos[i],
                uploadIcon: Icons.photo_library_outlined,
                photoIndex: i,
                onChanged: (p) async => setState(() => photos[i] = p),
                onRemoved: () => setState(() {
                  photos[i] = null;
                  photoTransforms[i] = const ElementTransform();
                  photoOpacities[i] = 1;
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Club logo & flag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _imageRow(
            label: 'Club Logo',
            keyName: 'logo',
            value: logo,
            uploadIcon: Icons.shield_outlined,
            onChanged: (p) async => setState(() => logo = p),
            onRemoved: () => setState(() => logo = null),
          ),
          const SizedBox(height: 8),
          _imageRow(
            label: 'Flag',
            keyName: 'flag',
            value: flag,
            uploadIcon: Icons.flag_outlined,
            onChanged: (p) async => setState(() => flag = p),
            onRemoved: () => setState(() => flag = null),
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
                      if (p != null) {
                        _beginChange();
                        setState(() => background = p);
                        _scheduleDraftSave();
                      }
                    },
                    icon: const Icon(Icons.wallpaper_rounded),
                    label: Text(background == null ? 'Upload background' : 'Replace background'),
                  ),
                ),
                if (background != null) ...[
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: () {
                      _beginChange();
                      setState(() => background = null);
                      _scheduleDraftSave();
                    },
                    tooltip: 'Use default background',
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_rounded),
              title: Text('Fixed card background'),
              subtitle: Text('This design uses a fixed background.'),
            ),
          ],
          if (widget.template.boosterSlots > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt_rounded),
              title: Text('${widget.template.boosterSlots} active booster${widget.template.boosterSlots == 1 ? '' : 's'}'),
              subtitle: const Text('All shown booster badges are active-looking.'),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: saving ? null : _saveCard,
              icon: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_done_rounded),
              label: Text(
                widget.existingCard != null
                    ? 'Update Card'
                    : (widget.template.coinCost == 0 ? 'Save Card • FREE' : 'Save Card • ${widget.template.coinCost} coins'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSnapshot {
  const _EditorSnapshot({
    required this.playerName,
    required this.rating,
    required this.position,
    required this.photos,
    required this.photoTransforms,
    required this.photoOpacities,
    required this.photoOrder,
    required this.logo,
    required this.flag,
    required this.background,
    required this.nameTransform,
    required this.ratingTransform,
  });

  final String playerName;
  final String rating;
  final String position;
  final List<String?> photos;
  final List<ElementTransform> photoTransforms;
  final List<double> photoOpacities;
  final List<int> photoOrder;
  final String? logo;
  final String? flag;
  final String? background;
  final ElementTransform nameTransform;
  final ElementTransform ratingTransform;

  String get signature => jsonEncode({
        'playerName': playerName,
        'rating': rating,
        'position': position,
        'photos': photos,
        'photoTransforms': photoTransforms.map((e) => e.toJson()).toList(),
        'photoOpacities': photoOpacities,
        'photoOrder': photoOrder,
        'logo': logo,
        'flag': flag,
        'background': background,
        'nameTransform': nameTransform.toJson(),
        'ratingTransform': ratingTransform.toJson(),
      });
}
