import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/card_template.dart';
import '../models/element_transform.dart';

class CardPreview extends StatelessWidget {
  const CardPreview({
    super.key,
    required this.template,
    this.playerName = 'YOUR NAME',
    this.rating = 90,
    this.position = 'CF',
    this.photoPaths = const [],
    this.photoTransforms = const [],
    this.photoOpacities = const [],
    this.photoOrder = const [],
    this.logoPath,
    this.flagPath,
    this.customBackgroundPath,
    this.nameTransform = const ElementTransform(),
    this.ratingTransform = const ElementTransform(),
    this.compact = false,
    this.interactive = false,
    this.onPhotoTransformChanged,
    this.onNameTransformChanged,
    this.onRatingTransformChanged,
    this.onGestureStart,
  });

  final CardTemplate template;
  final String playerName;
  final int rating;
  final String position;
  final List<String?> photoPaths;
  final List<ElementTransform> photoTransforms;
  final List<double> photoOpacities;
  final List<int> photoOrder;
  final String? logoPath;
  final String? flagPath;
  final String? customBackgroundPath;
  final ElementTransform nameTransform;
  final ElementTransform ratingTransform;
  final bool compact;
  final bool interactive;
  final void Function(int index, ElementTransform transform)? onPhotoTransformChanged;
  final ValueChanged<ElementTransform>? onNameTransformChanged;
  final ValueChanged<ElementTransform>? onRatingTransformChanged;
  final VoidCallback? onGestureStart;

  Widget _assetOrPlaceholder(
    String? path,
    IconData icon,
    String label, {
    bool photo = false,
  }) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: photo ? BoxFit.contain : BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: photo ? .24 : .34),
        border: Border.all(color: Colors.white.withValues(alpha: .30), width: compact ? .7 : 1),
        borderRadius: BorderRadius.circular(compact ? 5 : 9),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: compact ? 14 : 22),
          SizedBox(height: compact ? 1 : 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 6.2 : 9.5,
              color: Colors.white60,
              fontWeight: FontWeight.w800,
              letterSpacing: .35,
            ),
          ),
        ],
      ),
    );
  }

  Rect _photoRect(int index, Size s) {
    Rect r(double l, double t, double w, double h) => Rect.fromLTWH(
          s.width * l,
          s.height * t,
          s.width * w,
          s.height * h,
        );

    switch (template.id) {
      case 'base':
        return r(.39, .18, .48, .33);
      case 'potw':
      case 'potm':
        return r(.29, .16, .63, .53);
      case 'epic1':
        return index == 0 ? r(.44, .16, .49, .31) : r(.52, .42, .38, .27);
      case 'epic2a':
        return index == 0 ? r(.44, .16, .48, .30) : r(.53, .42, .36, .28);
      case 'epic2b':
        return index == 0 ? r(.38, .18, .51, .35) : r(.24, .46, .48, .27);
      case 'showtime':
        return r(.34, .16, .57, .50);
      case 'legendary':
        return r(.28, .18, .64, .49);
      case 'bt1':
        if (index == 0) return r(.59, .17, .34, .25);
        if (index == 1) return r(.26, .42, .33, .26);
        if (index == 2) return r(.51, .47, .28, .23);
        return r(.69, .38, .25, .26);
      case 'bt2':
        return index == 0 ? r(.48, .18, .42, .31) : r(.58, .47, .33, .27);
      case 'bt3':
        return index == 0 ? r(.34, .18, .56, .39) : r(.20, .48, .52, .24);
      case 'bt4':
        return index == 0 ? r(.36, .19, .53, .37) : r(.48, .47, .40, .25);
      case 'oldbt':
        return index == 0 ? r(.35, .18, .53, .34) : r(.50, .48, .33, .24);
      case 'special':
        return r(.31, .18, .59, .48);
      default:
        return r(.30, .18, .60, .50);
    }
  }

  ElementTransform _photoTransform(int index) {
    if (index < photoTransforms.length) return photoTransforms[index];
    return const ElementTransform();
  }

  double _photoOpacity(int index) {
    if (index < photoOpacities.length) return photoOpacities[index].clamp(.15, 1.0).toDouble();
    return 1;
  }

  List<int> _resolvedOrder() {
    final standard = List<int>.generate(template.photoSlots, (i) => i);
    if (photoOrder.length != template.photoSlots) return standard;
    final valid = photoOrder.toSet();
    if (valid.length != template.photoSlots || valid.any((e) => e < 0 || e >= template.photoSlots)) {
      return standard;
    }
    return List<int>.from(photoOrder);
  }

  Widget _photoLayer(int index, Rect rect, String? path) {
    final exists = path != null && path.isNotEmpty && File(path).existsSync();
    final content = exists
        ? Opacity(
            opacity: _photoOpacity(index),
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          )
        : _assetOrPlaceholder(path, Icons.person_add_alt_1_rounded, 'PHOTO ${index + 1}', photo: true);

    if (!exists) return content;

    return _TransformSurface(
      transform: _photoTransform(index),
      interactive: interactive && !compact,
      minScale: .45,
      maxScale: 4.0,
      snapThreshold: .035,
      onGestureStart: onGestureStart,
      onChanged: (value) => onPhotoTransformChanged?.call(index, value),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String?>.generate(
      template.photoSlots,
      (i) => i < photoPaths.length ? photoPaths[i] : null,
    );
    final order = _resolvedOrder();

    return AspectRatio(
      aspectRatio: .69,
      child: LayoutBuilder(
        builder: (context, c) {
          final s = Size(c.maxWidth, c.maxHeight);
          final hasCustomBackground = !template.backgroundLocked &&
              customBackgroundPath != null &&
              customBackgroundPath!.isNotEmpty &&
              File(customBackgroundPath!).existsSync();

          return ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 8 : 14),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                if (hasCustomBackground)
                  Image.file(File(customBackgroundPath!), fit: BoxFit.cover, filterQuality: FilterQuality.high)
                else
                  CustomPaint(painter: _TemplateBackgroundPainter(template: template)),
                if (hasCustomBackground) CustomPaint(painter: _TemplateOverlayPainter(template: template)),

                for (final i in order)
                  Positioned.fromRect(
                    rect: _photoRect(i, s),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(compact ? 5 : 9),
                      child: _photoLayer(i, _photoRect(i, s), photos[i]),
                    ),
                  ),

                Positioned(
                  left: s.width * .048,
                  top: s.height * .035,
                  width: s.width * .30,
                  height: s.height * .19,
                  child: _TransformSurface(
                    transform: ratingTransform,
                    interactive: interactive && !compact,
                    minScale: .65,
                    maxScale: 1.75,
                    snapThreshold: .025,
                    onGestureStart: onGestureStart,
                    onChanged: onRatingTransformChanged,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: s.width * .19,
                              height: .82,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: const [
                                Shadow(blurRadius: 5, color: Colors.black87),
                                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black87),
                              ],
                            ),
                          ),
                          Text(
                            position,
                            style: TextStyle(
                              fontSize: s.width * .093,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: s.width * .065,
                  top: s.height * .285,
                  width: s.width * .17,
                  height: s.width * .17,
                  child: _assetOrPlaceholder(logoPath, Icons.shield_outlined, 'LOGO'),
                ),
                Positioned(
                  left: s.width * .065,
                  top: s.height * .405,
                  width: s.width * .17,
                  height: s.width * .115,
                  child: _assetOrPlaceholder(flagPath, Icons.flag_outlined, 'FLAG'),
                ),

                Positioned(
                  left: s.width * .055,
                  right: s.width * .055,
                  bottom: s.height * (template.boosterSlots > 0 ? .145 : .095),
                  height: s.height * .105,
                  child: _TransformSurface(
                    transform: nameTransform,
                    interactive: interactive && !compact,
                    minScale: .55,
                    maxScale: 1.85,
                    snapThreshold: .025,
                    onGestureStart: onGestureStart,
                    onChanged: onNameTransformChanged,
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          playerName.trim().isEmpty ? 'YOUR NAME' : playerName,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: s.width * .13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: const [
                              Shadow(blurRadius: 7, color: Colors.black),
                              Shadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: s.height * (template.boosterSlots > 0 ? .070 : .020),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (_) => Icon(
                        Icons.star_rounded,
                        size: s.width * .071,
                        color: const Color(0xFFFFEA35),
                        shadows: const [Shadow(blurRadius: 2, color: Colors.black87)],
                      ),
                    ),
                  ),
                ),
                if (template.boosterSlots > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: s.height * .012,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        template.boosterSlots,
                        (i) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: s.width * .010),
                          child: _BoosterBadge(
                            size: s.width * .072,
                            tone: i.isEven ? const Color(0xFF00F2E6) : const Color(0xFFBFC3C8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransformSurface extends StatefulWidget {
  const _TransformSurface({
    required this.child,
    required this.transform,
    required this.interactive,
    required this.minScale,
    required this.maxScale,
    required this.snapThreshold,
    this.onChanged,
    this.onGestureStart,
  });

  final Widget child;
  final ElementTransform transform;
  final bool interactive;
  final double minScale;
  final double maxScale;
  final double snapThreshold;
  final ValueChanged<ElementTransform>? onChanged;
  final VoidCallback? onGestureStart;

  @override
  State<_TransformSurface> createState() => _TransformSurfaceState();
}

class _TransformSurfaceState extends State<_TransformSurface> {
  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite && c.maxWidth > 0 ? c.maxWidth : 1.0;
        final h = c.maxHeight.isFinite && c.maxHeight > 0 ? c.maxHeight : 1.0;
        final translated = Transform.translate(
          offset: Offset(widget.transform.dx * w, widget.transform.dy * h),
          child: Transform.scale(
            scale: widget.transform.scale,
            alignment: Alignment.center,
            child: widget.child,
          ),
        );

        if (!widget.interactive) return translated;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onScaleStart: (details) {
            widget.onGestureStart?.call();
            _startScale = widget.transform.scale;
            _startOffset = Offset(widget.transform.dx, widget.transform.dy);
            _startFocal = details.focalPoint;
          },
          onScaleUpdate: (details) {
            final rawDx = _startOffset.dx + (details.focalPoint.dx - _startFocal.dx) / w;
            final rawDy = _startOffset.dy + (details.focalPoint.dy - _startFocal.dy) / h;
            final dx = rawDx.abs() < widget.snapThreshold ? 0.0 : rawDx.clamp(-1.4, 1.4).toDouble();
            final dy = rawDy.abs() < widget.snapThreshold ? 0.0 : rawDy.clamp(-1.4, 1.4).toDouble();
            final scale = (_startScale * details.scale).clamp(widget.minScale, widget.maxScale).toDouble();
            widget.onChanged?.call(ElementTransform(dx: dx, dy: dy, scale: scale));
          },
          child: translated,
        );
      },
    );
  }
}

class _BoosterBadge extends StatelessWidget {
  const _BoosterBadge({required this.size, required this.tone});

  final double size;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _BoosterBadgePainter(tone)));
  }
}

class _BoosterBadgePainter extends CustomPainter {
  _BoosterBadgePainter(this.tone);
  final Color tone;

  Path _hex(Size s, double inset) {
    final w = s.width - inset * 2;
    final h = s.height - inset * 2;
    final x = inset;
    final y = inset;
    return Path()
      ..moveTo(x + w * .26, y)
      ..lineTo(x + w * .74, y)
      ..lineTo(x + w, y + h * .50)
      ..lineTo(x + w * .74, y + h)
      ..lineTo(x + w * .26, y + h)
      ..lineTo(x, y + h * .50)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size s) {
    final outer = _hex(s, s.width * .05);
    final inner = _hex(s, s.width * .18);
    final rect = Offset.zero & s;

    canvas.drawPath(
      outer,
      Paint()
        ..color = tone.withValues(alpha: .55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * .18),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.withValues(alpha: .82), const Color(0xFF050608), tone.withValues(alpha: .24)],
        ).createShader(rect),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = tone
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .07
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .025,
    );

    final mark = Paint()
      ..color = tone
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .075
      ..strokeCap = StrokeCap.round;
    final top = Rect.fromLTWH(s.width * .27, s.height * .27, s.width * .46, s.height * .28);
    final bottom = Rect.fromLTWH(s.width * .27, s.height * .45, s.width * .46, s.height * .28);
    canvas.drawArc(top, math.pi * .10, math.pi * 1.55, false, mark);
    canvas.drawArc(bottom, -math.pi * .55, math.pi * 1.55, false, mark);
    canvas.drawLine(Offset(s.width * .39, s.height * .50), Offset(s.width * .65, s.height * .50), mark);
  }

  @override
  bool shouldRepaint(covariant _BoosterBadgePainter oldDelegate) => oldDelegate.tone != tone;
}

class _TemplateBackgroundPainter extends CustomPainter {
  _TemplateBackgroundPainter({required this.template});
  final CardTemplate template;

  Paint _p(
    Color color, {
    PaintingStyle style = PaintingStyle.fill,
    double stroke = 1,
    MaskFilter? blur,
  }) {
    return Paint()
      ..color = color
      ..style = style
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = blur;
  }

  Rect _full(Size s) => Offset.zero & s;

  @override
  void paint(Canvas canvas, Size s) {
    switch (template.id) {
      case 'base':
        _base(canvas, s);
        break;
      case 'potw':
        _potw(canvas, s);
        break;
      case 'potm':
        _potm(canvas, s);
        break;
      case 'epic1':
        _epic1(canvas, s);
        break;
      case 'epic2a':
        _epic2a(canvas, s);
        break;
      case 'epic2b':
        _epic2b(canvas, s);
        break;
      case 'showtime':
        _showtime(canvas, s);
        break;
      case 'legendary':
        _legendary(canvas, s);
        break;
      case 'bt1':
        _bt1(canvas, s);
        break;
      case 'bt2':
        _bt2(canvas, s);
        break;
      case 'bt3':
        _bt3(canvas, s);
        break;
      case 'bt4':
        _bt4(canvas, s);
        break;
      case 'oldbt':
        _oldBt(canvas, s);
        break;
      case 'special':
        _special(canvas, s);
        break;
      default:
        _base(canvas, s);
        break;
    }
  }

  void _neonFrame(Canvas c, Size s, Color outer, Color inner, {double width = .012}) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * .02, s.height * .01, s.width * .96, s.height * .98),
      Radius.circular(s.width * .035),
    );
    c.drawRRect(
      rr,
      _p(
        outer.withValues(alpha: .50),
        style: PaintingStyle.stroke,
        stroke: s.width * width * 2.8,
        blur: MaskFilter.blur(BlurStyle.normal, s.width * .025),
      ),
    );
    c.drawRRect(rr, _p(inner, style: PaintingStyle.stroke, stroke: s.width * width));
  }

  void _polygon(Canvas c, List<Offset> points, Color color, {double stroke = 0, double alpha = 1}) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    c.drawPath(
      path,
      stroke > 0
          ? _p(color.withValues(alpha: alpha), style: PaintingStyle.stroke, stroke: stroke)
          : _p(color.withValues(alpha: alpha)),
    );
  }

  void _rays(Canvas c, Size s, Offset center, Color color, {int count = 20, double alpha = .15}) {
    for (var i = 0; i < count; i++) {
      final a = math.pi * 2 * i / count;
      final end = center + Offset(math.cos(a) * s.width * 1.1, math.sin(a) * s.height * .9);
      c.drawLine(center, end, _p(color.withValues(alpha: alpha), stroke: s.width * .012));
    }
  }

  void _clockRing(Canvas c, Size s, Offset center, Color gold, {double radius = .40}) {
    c.drawCircle(
      center,
      s.width * radius,
      _p(gold.withValues(alpha: .50), style: PaintingStyle.stroke, stroke: s.width * .025),
    );
    c.drawCircle(
      center,
      s.width * (radius - .07),
      _p(Colors.black.withValues(alpha: .46), style: PaintingStyle.stroke, stroke: s.width * .055),
    );
    for (var i = 0; i < 24; i++) {
      final a = math.pi * 2 * i / 24;
      final r1 = s.width * (radius - .015);
      final r2 = s.width * (radius + (i % 3 == 0 ? .055 : .032));
      c.drawLine(
        center + Offset(math.cos(a) * r1, math.sin(a) * r1),
        center + Offset(math.cos(a) * r2, math.sin(a) * r2),
        _p(gold.withValues(alpha: i % 3 == 0 ? .85 : .55), stroke: s.width * (i % 3 == 0 ? .012 : .007)),
      );
    }
  }

  void _base(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF090A0D), Color(0xFF0E1A1B), Color(0xFF071011), Color(0xFF3E210D)],
          stops: [0, .45, .72, 1],
        ).createShader(_full(s)),
    );
    final center = Offset(s.width * .64, s.height * .32);
    for (var i = 0; i < 4; i++) {
      c.drawArc(
        Rect.fromCenter(center: center, width: s.width * (.78 + i * .16), height: s.width * (.78 + i * .16)),
        -.8,
        4.4,
        false,
        _p(
          i.isEven ? const Color(0xFF2A5160).withValues(alpha: .50) : Colors.white.withValues(alpha: .10),
          style: PaintingStyle.stroke,
          stroke: s.width * .014,
        ),
      );
    }
    _polygon(c, [Offset(0, s.height * .61), Offset(s.width, s.height * .48), Offset(s.width, s.height * .61), Offset(0, s.height * .76)], const Color(0xFF0A5A54), alpha: .55);
    _polygon(c, [Offset(0, s.height * .71), Offset(s.width, s.height * .57), Offset(s.width, s.height * .70), Offset(0, s.height * .86)], const Color(0xFF082D31), alpha: .75);
    c.drawRect(
      Rect.fromLTWH(0, s.height * .79, s.width, s.height * .21),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0x003A1A00), Color(0xFF8B430E)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            .createShader(Rect.fromLTWH(0, s.height * .79, s.width, s.height * .21)),
    );
    _neonFrame(c, s, const Color(0xFF6EA7A8), Colors.white70, width: .008);
  }

  void _potw(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020604), Color(0xFF07160A), Color(0xFF001907), Color(0xFF06100A)],
        ).createShader(_full(s)),
    );
    final accent = const Color(0xFF00F536);
    for (var i = 0; i < 9; i++) {
      final x = s.width * (.72 + (i % 2) * .08);
      final y = s.height * (-.08 + i * .13);
      _polygon(
        c,
        [Offset(x, y), Offset(s.width * .98, y + s.height * .05), Offset(s.width * .80, y + s.height * .13), Offset(s.width * .66, y + s.height * .08)],
        accent,
        alpha: i.isEven ? .28 : .18,
      );
    }
    c.drawArc(
      Rect.fromCenter(center: Offset(s.width * .57, s.height * .40), width: s.width * 1.05, height: s.width * 1.05),
      -.7,
      4.5,
      false,
      _p(accent.withValues(alpha: .25), style: PaintingStyle.stroke, stroke: s.width * .025),
    );
    _neonFrame(c, s, accent, const Color(0xFF76FF8A), width: .010);
  }

  void _potm(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12031C), Color(0xFF3F0763), Color(0xFF160627)],
        ).createShader(_full(s)),
    );
    const purple = Color(0xFF8B22FF);
    const pink = Color(0xFFFF3BDF);
    for (var i = 0; i < 13; i++) {
      final y = s.height * (i / 13);
      final x = i.isEven ? s.width * .64 : s.width * .10;
      _polygon(
        c,
        [
          Offset(x, y),
          Offset((x + s.width * .30).clamp(0, s.width).toDouble(), y + s.height * .07),
          Offset((x + s.width * .16).clamp(0, s.width).toDouble(), y + s.height * .16),
          Offset((x - s.width * .05).clamp(0, s.width).toDouble(), y + s.height * .10),
        ],
        i.isEven ? purple : pink,
        alpha: .12 + (i % 3) * .035,
      );
    }
    _neonFrame(c, s, pink, purple, width: .010);
  }

  void _epic1(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001A14), Color(0xFF004B38), Color(0xFF03140F), Color(0xFF1B1307)],
          stops: [0, .42, .72, 1],
        ).createShader(_full(s)),
    );
    const green = Color(0xFF00B77B);
    const gold = Color(0xFFD6A647);
    final top = RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .12, s.height * .07, s.width * .78, s.height * .48), Radius.circular(s.width * .10));
    c.drawRRect(top, _p(green.withValues(alpha: .18), style: PaintingStyle.stroke, stroke: s.width * .03));
    for (var i = 0; i < 4; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s.width * (.07 + i * .025), s.height * (.05 + i * .025), s.width * (.86 - i * .05), s.height * (.55 - i * .03)), Radius.circular(s.width * .08)),
        _p(green.withValues(alpha: .12), style: PaintingStyle.stroke, stroke: s.width * .012),
      );
    }
    _polygon(c, [Offset(0, s.height * .64), Offset(s.width * .18, s.height * .58), Offset(s.width * .44, s.height * .67), Offset(s.width * .21, s.height * .74)], gold, alpha: .55);
    _polygon(c, [Offset(s.width, s.height * .62), Offset(s.width * .80, s.height * .58), Offset(s.width * .57, s.height * .68), Offset(s.width * .80, s.height * .75)], gold, alpha: .55);
    c.drawLine(Offset(s.width * .06, s.height * .73), Offset(s.width * .94, s.height * .73), _p(gold.withValues(alpha: .60), stroke: s.width * .018));
    _neonFrame(c, s, gold, const Color(0xFFE0BE69), width: .010);
  }

  void _epic2a(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.32, -.35),
          radius: 1.0,
          colors: [Color(0xFF6A4B13), Color(0xFF1F1608), Color(0xFF080705)],
        ).createShader(_full(s)),
    );
    const gold = Color(0xFFE9BD54);
    final center = Offset(s.width * .69, s.height * .38);
    for (var i = 0; i < 9; i++) {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(i * .16);
      c.translate(-center.dx, -center.dy);
      c.drawArc(
        Rect.fromCenter(center: center, width: s.width * (1.0 - i * .05), height: s.width * (.78 - i * .025)),
        -.9,
        4.3,
        false,
        _p(gold.withValues(alpha: .12 + i * .025), style: PaintingStyle.stroke, stroke: s.width * .035),
      );
      c.restore();
    }
    _rays(c, s, center, gold, count: 18, alpha: .06);
    _neonFrame(c, s, const Color(0xFF8C6A26), gold, width: .010);
  }

  void _epic2b(Canvas c, Size s) {
    c.drawRect(_full(s), _p(const Color(0xFF06070B)));
    const cyan = Color(0xFF00DFFF);
    const magenta = Color(0xFFFF2BD6);
    const violet = Color(0xFF8B38FF);
    final shards = <List<Offset>>[
      [Offset(0, 0), Offset(s.width * .42, 0), Offset(s.width * .20, s.height * .28)],
      [Offset(s.width, 0), Offset(s.width * .66, 0), Offset(s.width * .82, s.height * .30)],
      [Offset(0, s.height * .38), Offset(s.width * .25, s.height * .22), Offset(s.width * .18, s.height * .62)],
      [Offset(s.width, s.height * .31), Offset(s.width * .73, s.height * .23), Offset(s.width * .82, s.height * .64)],
      [Offset(0, s.height), Offset(s.width * .40, s.height * .74), Offset(s.width * .22, s.height)],
      [Offset(s.width, s.height), Offset(s.width * .61, s.height * .76), Offset(s.width * .81, s.height)],
    ];
    final colors = [cyan, violet, magenta, cyan, violet, magenta];
    for (var i = 0; i < shards.length; i++) {
      _polygon(c, shards[i], colors[i], alpha: .24);
      c.drawPath(
        Path()
          ..moveTo(shards[i][0].dx, shards[i][0].dy)
          ..lineTo(shards[i][1].dx, shards[i][1].dy)
          ..lineTo(shards[i][2].dx, shards[i][2].dy),
        _p(colors[i].withValues(alpha: .75), style: PaintingStyle.stroke, stroke: s.width * .018),
      );
    }
    _neonFrame(c, s, const Color(0xFFFF9A35), const Color(0xFFBA6D35), width: .009);
  }

  void _showtime(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF160621), Color(0xFF231D68), Color(0xFF050711)],
        ).createShader(_full(s)),
    );
    const cyan = Color(0xFF00DEFF);
    const purple = Color(0xFFA529FF);
    for (var i = 0; i < 7; i++) {
      final x = s.width * (.08 + i * .145);
      c.drawLine(Offset(x, 0), Offset(s.width * .5, s.height * .73), _p(i.isEven ? cyan.withValues(alpha: .24) : purple.withValues(alpha: .26), stroke: s.width * .025));
    }
    for (var i = 0; i < 6; i++) {
      final y = s.height * (.62 + i * .065);
      c.drawLine(Offset(0, y), Offset(s.width, y - s.height * .03), _p(purple.withValues(alpha: .20), stroke: s.width * .018));
    }
    _neonFrame(c, s, purple, cyan, width: .010);
  }

  void _legendary(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.08, -.15),
          radius: 1.0,
          colors: [Color(0xFFB88622), Color(0xFF4B330D), Color(0xFF090806)],
        ).createShader(_full(s)),
    );
    const gold = Color(0xFFFFCF59);
    final center = Offset(s.width * .53, s.height * .38);
    _rays(c, s, center, gold, count: 28, alpha: .08);
    for (var i = 0; i < 9; i++) {
      final a = math.pi * 2 * i / 9;
      final p1 = center + Offset(math.cos(a) * s.width * .25, math.sin(a) * s.width * .25);
      final p2 = center + Offset(math.cos(a + .24) * s.width * .55, math.sin(a + .24) * s.width * .55);
      final p3 = center + Offset(math.cos(a - .20) * s.width * .43, math.sin(a - .20) * s.width * .43);
      _polygon(c, [p1, p2, p3], gold, alpha: .10 + (i % 2) * .08);
    }
    c.drawCircle(center, s.width * .36, _p(Colors.black.withValues(alpha: .30)));
    _neonFrame(c, s, const Color(0xFF8B6720), gold, width: .010);
  }

  void _bt1(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.30, -.25),
          radius: 1.05,
          colors: [Color(0xFFFFB52D), Color(0xFFEF5A00), Color(0xFF5D1600), Color(0xFF100604)],
          stops: [0, .30, .68, 1],
        ).createShader(_full(s)),
    );
    const orange = Color(0xFFFF9B19);
    final center = Offset(s.width * .58, s.height * .40);
    _rays(c, s, center, orange, count: 22, alpha: .11);
    for (var i = 0; i < 5; i++) {
      c.drawArc(
        Rect.fromCenter(center: center, width: s.width * (.72 + i * .13), height: s.width * (.72 + i * .13)),
        -.7 + i * .14,
        4.4,
        false,
        _p(orange.withValues(alpha: .18), style: PaintingStyle.stroke, stroke: s.width * .035),
      );
    }
    _neonFrame(c, s, const Color(0xFFA56A25), const Color(0xFFFFC256), width: .010);
  }

  void _bt2(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.15, -.10),
          radius: 1.0,
          colors: [Color(0xFF5B2C55), Color(0xFF251127), Color(0xFF0C080A)],
        ).createShader(_full(s)),
    );
    const gold = Color(0xFFD8A845);
    final center = Offset(s.width * .61, s.height * .39);
    _clockRing(c, s, center, gold, radius: .43);
    c.drawCircle(center, s.width * .30, _p(const Color(0xFF2B151F).withValues(alpha: .65)));
    _neonFrame(c, s, const Color(0xFF805C25), const Color(0xFFE4B857), width: .010);
  }

  void _bt3(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF02061A), Color(0xFF032B85), Color(0xFF041231)],
        ).createShader(_full(s)),
    );
    const blue = Color(0xFF00A8FF);
    const cyan = Color(0xFF53E5FF);
    for (var i = 0; i < 11; i++) {
      final x = s.width * (i / 10);
      final tip = Offset(s.width * .50, s.height * (.10 + (i % 3) * .04));
      _polygon(c, [Offset(x - s.width * .08, s.height), Offset(x + s.width * .08, s.height), tip], i.isEven ? blue : cyan, alpha: .08 + (i % 4) * .025);
    }
    for (var i = 0; i < 5; i++) {
      c.drawArc(
        Rect.fromCenter(center: Offset(s.width * .53, s.height * .43), width: s.width * (.75 + i * .12), height: s.width * (.75 + i * .12)),
        -.9,
        4.5,
        false,
        _p(cyan.withValues(alpha: .14), style: PaintingStyle.stroke, stroke: s.width * .025),
      );
    }
    _neonFrame(c, s, const Color(0xFF006BFF), cyan, width: .010);
  }

  void _bt4(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.15, -.10),
          radius: 1.0,
          colors: [Color(0xFFAF2104), Color(0xFF4B1105), Color(0xFF100705)],
        ).createShader(_full(s)),
    );
    const orange = Color(0xFFFF6C13);
    final center = Offset(s.width * .56, s.height * .39);
    _clockRing(c, s, center, orange, radius: .42);
    _rays(c, s, center, orange, count: 16, alpha: .06);
    _neonFrame(c, s, const Color(0xFF8C541E), const Color(0xFFFF9E3B), width: .010);
  }

  void _oldBt(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.20, -.15),
          radius: 1.0,
          colors: [Color(0xFF625014), Color(0xFF221A08), Color(0xFF080705)],
        ).createShader(_full(s)),
    );
    const gold = Color(0xFFEAC85D);
    final center = Offset(s.width * .58, s.height * .39);
    _clockRing(c, s, center, gold, radius: .44);
    c.drawArc(
      Rect.fromCenter(center: center, width: s.width * 1.05, height: s.width * 1.05),
      -.7,
      3.9,
      false,
      _p(gold.withValues(alpha: .18), style: PaintingStyle.stroke, stroke: s.width * .055),
    );
    _neonFrame(c, s, const Color(0xFF7B6020), gold, width: .010);
  }

  void _special(Canvas c, Size s) {
    c.drawRect(
      _full(s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16051C), Color(0xFF5C0B5B), Color(0xFF06191C)],
        ).createShader(_full(s)),
    );
    const magenta = Color(0xFFFF17C8);
    const cyan = Color(0xFF18D7D7);
    const purple = Color(0xFF9E3BFF);
    final shards = <List<Offset>>[
      [Offset(0, s.height * .13), Offset(s.width * .55, 0), Offset(s.width * .25, s.height * .38)],
      [Offset(s.width, s.height * .06), Offset(s.width * .70, 0), Offset(s.width * .76, s.height * .43)],
      [Offset(0, s.height * .58), Offset(s.width * .31, s.height * .40), Offset(s.width * .22, s.height * .86)],
      [Offset(s.width, s.height * .55), Offset(s.width * .73, s.height * .40), Offset(s.width * .78, s.height * .86)],
      [Offset(0, s.height), Offset(s.width * .48, s.height * .72), Offset(s.width * .25, s.height)],
      [Offset(s.width, s.height), Offset(s.width * .55, s.height * .76), Offset(s.width * .79, s.height)],
    ];
    final colors = [magenta, cyan, purple, magenta, cyan, purple];
    for (var i = 0; i < shards.length; i++) {
      _polygon(c, shards[i], colors[i], alpha: .28);
    }
    _neonFrame(c, s, magenta, const Color(0xFFFF82EF), width: .010);
  }

  @override
  bool shouldRepaint(covariant _TemplateBackgroundPainter oldDelegate) => oldDelegate.template.id != template.id;
}

class _TemplateOverlayPainter extends CustomPainter {
  _TemplateOverlayPainter({required this.template});
  final CardTemplate template;

  @override
  void paint(Canvas canvas, Size s) {
    final accent = template.id == 'potw' ? const Color(0xFF00F536) : const Color(0xFF9228FF);
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * .02, s.height * .01, s.width * .96, s.height * .98),
      Radius.circular(s.width * .035),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .010,
    );
    if (template.id == 'potw' || template.id == 'potm') {
      final p = Paint()
        ..color = accent.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .025
        ..strokeCap = StrokeCap.round;
      for (var y = -.04; y < 1.1; y += .17) {
        final path = Path()
          ..moveTo(s.width * .70, s.height * y)
          ..lineTo(s.width * .90, s.height * (y + .06))
          ..lineTo(s.width * .75, s.height * (y + .14));
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TemplateOverlayPainter oldDelegate) => oldDelegate.template.id != template.id;
}
