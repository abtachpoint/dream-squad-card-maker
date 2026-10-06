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
import '../models/element_transform.dart';
import '../models/squad_project.dart';
import '../widgets/app_notice.dart';
import '../widgets/coin_badge.dart';

class SquadBuilderScreen extends StatefulWidget {
  const SquadBuilderScreen({
    super.key,
    this.embedded = false,
    this.existingSquad,
  });

  final bool embedded;
  final SquadProject? existingSquad;

  @override
  State<SquadBuilderScreen> createState() => _SquadBuilderScreenState();
}

class _SquadBuilderScreenState extends State<SquadBuilderScreen> {
  static const galleryChannel = MethodChannel('com.soikot.dreamsquad/gallery');
  final previewKey = GlobalKey();
  late final TextEditingController teamName;
  late final TextEditingController managerName;
  final picker = ImagePicker();

  String formation = '4-3-3';
  bool customFormation = false;
  bool positionsLocked = false;
  int fieldStyle = 0;
  String? customBackground;
  String? teamLogo;
  String? managerPhoto;
  int? captainIndex;
  late List<CardProject?> slots;
  late List<ElementTransform> playerTransforms;
  final List<CardProject> bench = [];
  bool showBench = false;
  bool exporting = false;
  bool captureClean = false;

  final Map<String, List<Alignment>> formations = const {
    '4-3-3': [
      Alignment(-.72, -.55),
      Alignment(0, -.68),
      Alignment(.72, -.55),
      Alignment(-.55, -.05),
      Alignment(0, .02),
      Alignment(.55, -.05),
      Alignment(-.78, .50),
      Alignment(-.28, .43),
      Alignment(.28, .43),
      Alignment(.78, .50),
      Alignment(0, .82),
    ],
    '4-2-3-1': [
      Alignment(0, -.68),
      Alignment(-.70, -.34),
      Alignment(0, -.30),
      Alignment(.70, -.34),
      Alignment(-.35, .05),
      Alignment(.35, .05),
      Alignment(-.78, .50),
      Alignment(-.28, .43),
      Alignment(.28, .43),
      Alignment(.78, .50),
      Alignment(0, .82),
    ],
    '4-4-2': [
      Alignment(-.32, -.62),
      Alignment(.32, -.62),
      Alignment(-.75, -.10),
      Alignment(-.25, .02),
      Alignment(.25, .02),
      Alignment(.75, -.10),
      Alignment(-.78, .50),
      Alignment(-.28, .43),
      Alignment(.28, .43),
      Alignment(.78, .50),
      Alignment(0, .82),
    ],
    '3-5-2': [
      Alignment(-.30, -.62),
      Alignment(.30, -.62),
      Alignment(-.78, -.12),
      Alignment(-.38, .02),
      Alignment(0, -.05),
      Alignment(.38, .02),
      Alignment(.78, -.12),
      Alignment(-.55, .48),
      Alignment(0, .40),
      Alignment(.55, .48),
      Alignment(0, .82),
    ],
    '4-1-2-3': [
      Alignment(-.72, -.55),
      Alignment(0, -.68),
      Alignment(.72, -.55),
      Alignment(-.42, -.08),
      Alignment(.42, -.08),
      Alignment(0, .22),
      Alignment(-.78, .50),
      Alignment(-.28, .43),
      Alignment(.28, .43),
      Alignment(.78, .50),
      Alignment(0, .82),
    ],
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSquad;
    teamName = TextEditingController(text: existing?.name ?? 'MY DREAM SQUAD');
    managerName = TextEditingController(text: existing?.managerName ?? '');
    formation = formations.containsKey(existing?.formation) ? existing!.formation : '4-3-3';
    customFormation = existing?.customFormation ?? false;
    positionsLocked = existing?.positionsLocked ?? false;
    fieldStyle = existing?.fieldStyle ?? 0;
    customBackground = existing?.customBackgroundPath;
    teamLogo = existing?.teamLogoPath;
    managerPhoto = existing?.managerPhotoPath;
    captainIndex = existing?.captainIndex;
    showBench = existing?.showBench ?? false;

    final ids = existing?.playerCardIds ?? const <String?>[];
    slots = List<CardProject?>.generate(11, (i) {
      if (i >= ids.length || ids[i] == null) return null;
      return appState.cards.where((c) => c.id == ids[i]).firstOrNull;
    });

    final savedPositions = existing?.playerTransforms ?? const <ElementTransform>[];
    final base = formations[formation]!;
    playerTransforms = List<ElementTransform>.generate(11, (i) {
      if (i < savedPositions.length) return savedPositions[i];
      return ElementTransform(dx: base[i].x, dy: base[i].y);
    });

    final benchIds = existing?.benchCardIds ?? const <String>[];
    for (final id in benchIds) {
      final card = appState.cards.where((c) => c.id == id).firstOrNull;
      if (card != null) bench.add(card);
    }
  }

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

  Future<CardProject?> _pickCard({Set<String> excludedIds = const {}}) async {
    final available = appState.cards.where((c) => !excludedIds.contains(c.id)).toList();
    if (available.isEmpty) {
      await showAppNotice(
        context,
        title: appState.cards.isEmpty ? 'No player cards yet' : 'No more cards available',
        message: appState.cards.isEmpty
            ? 'Create at least one player card before adding players to a squad.'
            : 'Every available saved card is already used in this squad or bench.',
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
          height: MediaQuery.of(context).size.height * .64,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Choose player card', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: .66,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final c = available[i];
                    final file = File(c.previewPath);
                    return InkWell(
                      onTap: () => Navigator.pop(context, c),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: file.existsSync()
                                  ? Image.file(file, fit: BoxFit.cover, width: double.infinity)
                                  : Container(color: Colors.white10),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.playerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
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

  Set<String> get _usedCardIds => {
        ...slots.whereType<CardProject>().map((e) => e.id),
        ...bench.map((e) => e.id),
      };

  Future<void> _chooseCard(int slotIndex) async {
    final current = slots[slotIndex];
    final excluded = _usedCardIds..remove(current?.id);
    final picked = await _pickCard(excludedIds: excluded);
    if (picked != null && mounted) setState(() => slots[slotIndex] = picked);
  }

  Future<void> _addCustomPlayer() async {
    final firstEmpty = slots.indexWhere((e) => e == null);
    if (firstEmpty < 0) {
      await showAppNotice(
        context,
        title: 'Squad is full',
        message: 'You already have 11 players on the field.',
        icon: Icons.groups_rounded,
        accent: Colors.orangeAccent,
      );
      return;
    }
    final picked = await _pickCard(excludedIds: _usedCardIds);
    if (picked == null || !mounted) return;
    final base = formations[formation]![firstEmpty];
    setState(() {
      slots[firstEmpty] = picked;
      playerTransforms[firstEmpty] = ElementTransform(dx: base.x, dy: base.y);
    });
  }

  Future<void> _addBenchPlayer() async {
    if (bench.length >= 7) {
      await showAppNotice(
        context,
        title: 'Bench is full',
        message: 'The optional bench supports up to 7 players.',
        icon: Icons.event_seat_rounded,
        accent: Colors.orangeAccent,
      );
      return;
    }
    final picked = await _pickCard(excludedIds: _usedCardIds);
    if (picked != null && mounted) setState(() => bench.add(picked));
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
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Replace player'),
              onTap: () => Navigator.pop(context, 'replace'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_rounded),
              title: Text(captainIndex == index ? 'Remove captain' : 'Make captain'),
              onTap: () => Navigator.pop(context, 'captain'),
            ),
            if (customFormation)
              ListTile(
                leading: const Icon(Icons.center_focus_strong_rounded),
                title: const Text('Reset this player position'),
                onTap: () => Navigator.pop(context, 'reset'),
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Remove from field'),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'replace') {
      await _chooseCard(index);
    } else if (action == 'captain') {
      setState(() => captainIndex = captainIndex == index ? null : index);
    } else if (action == 'reset') {
      final a = formations[formation]![index];
      setState(() => playerTransforms[index] = ElementTransform(dx: a.x, dy: a.y));
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

  void _resetCustomFormation() {
    final base = formations[formation]!;
    setState(() {
      for (var i = 0; i < 11; i++) {
        playerTransforms[i] = ElementTransform(dx: base[i].x, dy: base[i].y);
      }
    });
  }

  void _changeFormation(String next) {
    setState(() {
      formation = next;
      if (!customFormation) return;
      final base = formations[next]!;
      for (var i = 0; i < 11; i++) {
        if (slots[i] != null) {
          playerTransforms[i] = ElementTransform(dx: base[i].x, dy: base[i].y);
        }
      }
    });
  }

  Future<Uint8List> _capture() async {
    setState(() => captureClean = true);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    try {
      final boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not render squad image.');
      return data.buffer.asUint8List();
    } finally {
      if (mounted) setState(() => captureClean = false);
    }
  }

  SquadProject _buildProject(String previewPath) {
    return SquadProject(
      id: widget.existingSquad?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: teamName.text.trim().isEmpty ? 'My Dream Squad' : teamName.text.trim(),
      formation: formation,
      previewPath: previewPath,
      customFormation: customFormation,
      playerCardIds: slots.map((e) => e?.id).toList(),
      playerTransforms: List<ElementTransform>.from(playerTransforms),
      captainIndex: captainIndex,
      fieldStyle: fieldStyle,
      customBackgroundPath: customBackground,
      teamLogoPath: teamLogo,
      managerName: managerName.text.trim(),
      managerPhotoPath: managerPhoto,
      showBench: showBench,
      benchCardIds: bench.map((e) => e.id).toList(),
      positionsLocked: positionsLocked,
    );
  }

  Future<void> _saveSquad() async {
    if (exporting) return;
    if (slots.whereType<CardProject>().isEmpty) {
      await showAppNotice(
        context,
        title: 'Add at least 1 player',
        message: 'A squad can use 1–11 players. Add a saved player card first.',
        icon: Icons.person_add_alt_1_rounded,
        accent: Colors.orangeAccent,
      );
      return;
    }
    setState(() => exporting = true);
    try {
      final bytes = await _capture();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/squad_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);
      final project = _buildProject(file.path);
      if (widget.existingSquad == null) {
        await appState.addSquad(project);
      } else {
        await appState.updateSquad(project);
      }
      if (mounted) {
        await showAppNotice(
          context,
          title: widget.existingSquad == null ? 'Squad saved' : 'Squad updated',
          message: '${slots.whereType<CardProject>().length} player${slots.whereType<CardProject>().length == 1 ? '' : 's'} saved. A full 11 is not required.',
          icon: Icons.check_circle_rounded,
          accent: Colors.greenAccent,
        );
      }
    } catch (_) {
      if (mounted) {
        await showAppNotice(
          context,
          title: 'Couldn’t save squad',
          message: 'Please try again.',
          icon: Icons.error_outline_rounded,
          accent: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _export() async {
    if (exporting) return;
    if (slots.whereType<CardProject>().isEmpty) {
      await showAppNotice(
        context,
        title: 'Add at least 1 player',
        message: 'A squad can use 1–11 players. Add a saved player card first.',
        icon: Icons.person_add_alt_1_rounded,
        accent: Colors.orangeAccent,
      );
      return;
    }
    setState(() => exporting = true);
    try {
      final bytes = await _capture();
      await galleryChannel.invokeMethod('saveImage', {
        'bytes': bytes,
        'fileName': 'DreamSquad_Lineup_${DateTime.now().millisecondsSinceEpoch}.png',
      });
      if (mounted) {
        await showAppNotice(
          context,
          title: 'Squad exported',
          message: 'Saved in high quality to Pictures/Dream Squad Card Maker.',
          icon: Icons.check_circle_rounded,
          accent: Colors.greenAccent,
        );
      }
    } catch (_) {
      if (mounted) {
        await showAppNotice(
          context,
          title: 'Export failed',
          message: 'Couldn’t save the squad image. Please try again.',
          icon: Icons.error_outline_rounded,
          accent: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget _cardCore(int index, {double width = 58, double height = 78}) {
    final card = slots[index];
    if (card == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white38),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white70),
      );
    }

    final file = File(card.previewPath);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file.existsSync() ? Image.file(file, fit: BoxFit.cover) : Container(color: Colors.white10),
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
    );
  }

  Widget _fixedPlayerSlot(
    int index,
    Alignment alignment, {
    bool interactive = true,
    bool clean = false,
  }) {
    final card = slots[index];
    if (clean && card == null) return const SizedBox.shrink();
    final staticCore = _cardCore(index);
    final core = interactive
        ? GestureDetector(onTap: () => _slotActions(index), child: staticCore)
        : staticCore;

    return Align(
      alignment: alignment,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => _swap(details.data, index),
        builder: (context, candidates, rejected) {
          final highlighted = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: highlighted
                ? BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white70, width: 2))
                : null,
            child: card == null || !interactive
                ? core
                : LongPressDraggable<int>(
                    data: index,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(opacity: .88, child: _cardCore(index)),
                    ),
                    childWhenDragging: Opacity(opacity: .30, child: core),
                    child: core,
                  ),
          );
        },
      ),
    );
  }

  Widget _customPlayer(int index, Size area, {bool interactive = true}) {
    final card = slots[index];
    if (card == null) return const SizedBox.shrink();
    final t = playerTransforms[index];
    const cardW = 58.0;
    const cardH = 78.0;
    final usableW = mathMax(1, area.width - cardW);
    final usableH = mathMax(1, area.height - cardH);
    final left = ((t.dx + 1) / 2 * usableW).clamp(0, usableW).toDouble();
    final top = ((t.dy + 1) / 2 * usableH).clamp(0, usableH).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: interactive ? () => _slotActions(index) : null,
        onPanUpdate: !interactive || positionsLocked
            ? null
            : (details) {
                setState(() {
                  final nextX = (playerTransforms[index].dx + details.delta.dx * 2 / usableW).clamp(-1.0, 1.0).toDouble();
                  final nextY = (playerTransforms[index].dy + details.delta.dy * 2 / usableH).clamp(-1.0, 1.0).toDouble();
                  playerTransforms[index] = ElementTransform(dx: nextX, dy: nextY);
                });
              },
        child: _cardCore(index, width: cardW, height: cardH),
      ),
    );
  }

  Widget _buildPitch({bool interactive = true, bool clean = false}) {
    final customBgFile = customBackground == null ? null : File(customBackground!);
    final logoFile = teamLogo == null ? null : File(teamLogo!);
    final managerFile = managerPhoto == null ? null : File(managerPhoto!);
    final fixedAlignments = formations[formation]!;

    return AspectRatio(
      aspectRatio: .72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, box) {
            final area = Size(box.maxWidth, box.maxHeight);
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
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
                DecoratedBox(
                  decoration: BoxDecoration(color: customBgFile != null ? Colors.black.withValues(alpha: .20) : Colors.transparent),
                ),
                CustomPaint(painter: _PitchPainter()),

                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 58),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                teamName.text.trim().isEmpty ? 'MY DREAM SQUAD' : teamName.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (logoFile != null && logoFile.existsSync())
                        Positioned(
                          left: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(logoFile, width: 36, height: 36, fit: BoxFit.contain),
                          ),
                        ),
                    ],
                  ),
                ),

                if (!customFormation)
                  ...List.generate(
                    11,
                    (i) => _fixedPlayerSlot(
                      i,
                      fixedAlignments[i],
                      interactive: interactive,
                      clean: clean,
                    ),
                  )
                else
                  ...List.generate(
                    11,
                    (i) => _customPlayer(i, area, interactive: interactive),
                  ),

                if (managerName.text.trim().isNotEmpty || (managerFile != null && managerFile.existsSync()))
                  Positioned(
                    left: 10,
                    bottom: showBench ? 56 : 8,
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
                          Text(
                            managerName.text.trim().isEmpty ? 'Manager' : managerName.text,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showBench)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 6,
                    height: 46,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Text('BENCH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white70)),
                          ),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: bench.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 4),
                              itemBuilder: (_, i) {
                                final file = File(bench[i].previewPath);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: file.existsSync()
                                      ? Image.file(file, width: 27, height: 38, fit: BoxFit.cover)
                                      : Container(width: 27, height: 38, color: Colors.white10),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (customFormation && positionsLocked)
                  Positioned(
                    right: 10,
                    top: 54,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 12),
                          SizedBox(width: 3),
                          Text('LOCKED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showFullPreview() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Squad Preview'),
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: _buildPitch(interactive: false, clean: true)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final playerCount = slots.whereType<CardProject>().length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Expanded(child: Text('Squad Builder', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: _showFullPreview, tooltip: 'Full-screen preview', icon: const Icon(Icons.fullscreen_rounded)),
                  const CoinBadge(),
                ],
              ),
            ),
          RepaintBoundary(
            key: previewKey,
            child: _buildPitch(
              interactive: !captureClean,
              clean: captureClean,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$playerCount/11 players on field • You can save with fewer than 11 players.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: teamName,
            onChanged: (_) => setState(() {}),
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Team name', counterText: ''),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.grid_view_rounded), label: Text('Fixed Formation')),
              ButtonSegment(value: true, icon: Icon(Icons.open_with_rounded), label: Text('Custom Formation')),
            ],
            selected: {customFormation},
            onSelectionChanged: (value) {
              setState(() => customFormation = value.first);
              if (customFormation && playerCount == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _addCustomPlayer();
                });
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: formation,
            decoration: InputDecoration(labelText: customFormation ? 'Starting layout / reset layout' : 'Formation'),
            items: formations.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) {
              if (v != null) _changeFormation(v);
            },
          ),
          if (customFormation) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _addCustomPlayer,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add Player'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetCustomFormation,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset Positions'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: positionsLocked,
              onChanged: (v) => setState(() => positionsLocked = v),
              secondary: Icon(positionsLocked ? Icons.lock_rounded : Icons.lock_open_rounded),
              title: const Text('Lock custom positions'),
              subtitle: Text(positionsLocked ? 'Player cards cannot move accidentally.' : 'Drag player cards freely with your finger.'),
            ),
          ],
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Green')),
              ButtonSegment(value: 1, label: Text('Dark')),
              ButtonSegment(value: 2, label: Text('Purple')),
            ],
            selected: {fieldStyle},
            onSelectionChanged: (v) => setState(() {
              fieldStyle = v.first;
              customBackground = null;
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final p = await _pickAndCrop(wide: true);
                    if (p != null) setState(() => customBackground = p);
                  },
                  icon: const Icon(Icons.wallpaper_rounded),
                  label: Text(customBackground == null ? 'Upload custom background' : 'Replace custom background'),
                ),
              ),
              if (customBackground != null)
                IconButton(
                  onPressed: () => setState(() => customBackground = null),
                  tooltip: 'Remove custom background',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
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
              if (teamLogo != null)
                IconButton(onPressed: () => setState(() => teamLogo = null), icon: const Icon(Icons.close_rounded), tooltip: 'Remove logo'),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: managerName,
            onChanged: (_) => setState(() {}),
            maxLength: 28,
            decoration: const InputDecoration(labelText: 'Manager name (optional)', counterText: ''),
          ),
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
              if (managerPhoto != null)
                IconButton(onPressed: () => setState(() => managerPhoto = null), icon: const Icon(Icons.close_rounded), tooltip: 'Remove manager photo'),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: showBench,
            onChanged: (v) => setState(() => showBench = v),
            secondary: const Icon(Icons.event_seat_rounded),
            title: const Text('Show bench'),
            subtitle: const Text('Optional bench section with up to 7 players.'),
          ),
          if (showBench) ...[
            Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...bench.asMap().entries.map((entry) {
                  final i = entry.key;
                  final card = entry.value;
                  final file = File(card.previewPath);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: file.existsSync()
                            ? Image.file(file, width: 44, height: 60, fit: BoxFit.cover)
                            : Container(width: 44, height: 60, color: Colors.white10),
                      ),
                      Positioned(
                        right: -7,
                        top: -7,
                        child: InkWell(
                          onTap: () => setState(() => bench.removeAt(i)),
                          child: const CircleAvatar(radius: 10, child: Icon(Icons.close_rounded, size: 13)),
                        ),
                      ),
                    ],
                  );
                }),
                OutlinedButton.icon(
                  onPressed: bench.length >= 7 ? null : _addBenchPlayer,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add bench player'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            customFormation
                ? 'Custom mode: add 1–11 players, then drag each card anywhere on the pitch. Tap a card for replace, captain or remove.'
                : 'Fixed mode: tap any slot to add/manage a player. Long-press and drag a filled card to swap positions. Empty slots are allowed when saving.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.tonalIcon(
                    onPressed: exporting ? null : _saveSquad,
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: Text(widget.existingSquad == null ? 'Save Squad' : 'Update Squad'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: exporting ? null : _export,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(exporting ? 'Saving…' : 'Export'),
                  ),
                ),
              ),
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
      appBar: AppBar(
        title: Text(widget.existingSquad == null ? 'Squad Builder' : 'Edit Squad'),
        actions: [
          IconButton(onPressed: _showFullPreview, tooltip: 'Full-screen preview', icon: const Icon(Icons.fullscreen_rounded)),
          const Padding(padding: EdgeInsets.only(right: 14), child: Center(child: CoinBadge())),
        ],
      ),
      body: _buildContent(),
    );
  }
}

double mathMax(double a, double b) => a > b ? a : b;

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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) return item;
    return null;
  }
}
