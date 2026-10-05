import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_template.dart';

class CardPreview extends StatelessWidget {
  const CardPreview({
    super.key,
    required this.template,
    this.playerName = 'YOUR NAME',
    this.rating = 90,
    this.position = 'CF',
    this.photoPaths = const [],
    this.logoPath,
    this.flagPath,
    this.customBackgroundPath,
    this.compact = false,
  });

  final CardTemplate template;
  final String playerName;
  final int rating;
  final String position;
  final List<String?> photoPaths;
  final String? logoPath;
  final String? flagPath;
  final String? customBackgroundPath;
  final bool compact;

  Widget _assetOrPlaceholder(
    String? path,
    IconData icon,
    String label, {
    bool photo = false,
  }) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: photo ? BoxFit.contain : BoxFit.cover);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: photo ? .14 : .24),
        border: Border.all(color: Colors.white.withValues(alpha: .28), width: 1),
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: compact ? 15 : 23),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 6.5 : 10,
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }

  Rect _photoRect(int index, Size s) {
    final id = template.id;
    Rect r(double l, double t, double w, double h) => Rect.fromLTWH(s.width * l, s.height * t, s.width * w, s.height * h);

    switch (id) {
      case 'base':
        return r(.36, .045, .59, .39);
      case 'potw':
      case 'potm':
        return r(.25, .045, .70, .77);
      case 'epic1':
        return index == 0 ? r(.30, .03, .68, .70) : r(.10, .34, .43, .50);
      case 'showtime':
        return r(.28, .045, .66, .78);
      case 'epic2a':
        return index == 0 ? r(.28, .03, .69, .62) : r(.20, .34, .45, .52);
      case 'epic2b':
        return index == 0 ? r(.34, .03, .63, .61) : r(.06, .35, .53, .54);
      case 'bt1':
        if (index == 0) return r(.22, .01, .76, .49);
        if (index == 1) return r(.02, .38, .43, .43);
        if (index == 2) return r(.38, .39, .38, .48);
        return r(.64, .35, .34, .49);
      case 'bt2':
        return index == 0 ? r(.25, .02, .72, .67) : r(.16, .37, .47, .50);
      case 'bt3':
        return index == 0 ? r(.30, .03, .66, .58) : r(.08, .39, .66, .43);
      case 'bt4':
        return index == 0 ? r(.27, .03, .70, .69) : r(.34, .36, .46, .48);
      case 'bt5':
        return index == 0 ? r(.29, .02, .68, .66) : r(.24, .37, .51, .49);
      case 'legendary':
        return r(.08, .05, .90, .79);
      case 'oldbt':
        return r(.20, .04, .78, .80);
      default:
        return r(.28, .06, .68, .72);
    }
  }

  bool get _showLogo => true;
  bool get _showFlag => true;

  Alignment get _nameAlignment {
    if (template.id == 'potw' || template.id == 'potm') return Alignment.center;
    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String?>.generate(template.photoSlots, (i) => i < photoPaths.length ? photoPaths[i] : null);

    return AspectRatio(
      aspectRatio: 0.69,
      child: LayoutBuilder(
        builder: (context, c) {
          final s = Size(c.maxWidth, c.maxHeight);
          return ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 8 : 14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!template.backgroundLocked && customBackgroundPath != null && File(customBackgroundPath!).existsSync())
                  Image.file(File(customBackgroundPath!), fit: BoxFit.cover)
                else
                  CustomPaint(painter: _TemplateBackgroundPainter(template: template)),
                if (!template.backgroundLocked && customBackgroundPath != null && File(customBackgroundPath!).existsSync())
                  CustomPaint(painter: _TemplateOverlayPainter(template: template)),

                for (int i = 0; i < template.photoSlots; i++)
                  Positioned.fromRect(
                    rect: _photoRect(i, s),
                    child: _assetOrPlaceholder(photos[i], Icons.person_add_alt_1_rounded, 'PHOTO ${i + 1}', photo: true),
                  ),

                Positioned(
                  left: s.width * .055,
                  top: s.height * .035,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$rating',
                        style: TextStyle(
                          fontSize: s.width * .19,
                          height: .82,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [Shadow(blurRadius: 5, color: Colors.black87)],
                        ),
                      ),
                      Text(
                        position,
                        style: TextStyle(
                          fontSize: s.width * .095,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showLogo)
                  Positioned(
                    left: s.width * .065,
                    top: s.height * .245,
                    width: s.width * .20,
                    height: s.width * .20,
                    child: _assetOrPlaceholder(logoPath, Icons.shield_outlined, 'LOGO'),
                  ),
                if (_showFlag)
                  Positioned(
                    left: s.width * .065,
                    top: _showLogo ? s.height * .365 : s.height * .245,
                    width: s.width * .20,
                    height: s.width * .135,
                    child: _assetOrPlaceholder(flagPath, Icons.flag_outlined, 'FLAG'),
                  ),

                Positioned(
                  left: s.width * .055,
                  right: s.width * .055,
                  bottom: s.height * (template.boosterSlots > 0 ? .085 : .06),
                  child: Align(
                    alignment: _nameAlignment,
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

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: s.height * .015,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (template.boosterSlots > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            template.boosterSlots,
                            (i) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: s.width * .010),
                              child: _BoosterBadge(
                                size: s.width * .074,
                                tone: i.isEven ? const Color(0xFF00F1E6) : const Color(0xFFFFE64B),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: s.height * .006),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (_) => Icon(Icons.star_rounded, size: s.width * .07, color: const Color(0xFFFFEA35)),
                        ),
                      ),
                    ],
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
    final inner = _hex(s, s.width * .16);

    canvas.drawPath(
      outer,
      Paint()
        ..color = tone.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * .18),
    );

    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: .48),
            const Color(0xFF050609),
            tone.withValues(alpha: .18),
          ],
        ).createShader(Offset.zero & s),
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
        ..color = Colors.white.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .025
        ..strokeJoin = StrokeJoin.round,
    );

    // Original energy/booster mark: twin open curves and a short center bar.
    // It keeps the familiar active-booster feel without copying an official logo.
    final mark = Paint()
      ..color = tone
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .075
      ..strokeCap = StrokeCap.round;

    final top = Rect.fromLTWH(s.width * .27, s.height * .27, s.width * .46, s.height * .28);
    final bottom = Rect.fromLTWH(s.width * .27, s.height * .45, s.width * .46, s.height * .28);
    canvas.drawArc(top, math.pi * .10, math.pi * 1.55, false, mark);
    canvas.drawArc(bottom, -math.pi * .55, math.pi * 1.55, false, mark);
    canvas.drawLine(
      Offset(s.width * .39, s.height * .50),
      Offset(s.width * .65, s.height * .50),
      mark,
    );
  }

  @override
  bool shouldRepaint(covariant _BoosterBadgePainter oldDelegate) => oldDelegate.tone != tone;
}

class _TemplateBackgroundPainter extends CustomPainter {
  _TemplateBackgroundPainter({required this.template});
  final CardTemplate template;

  Paint _paint(Color c, {PaintingStyle style = PaintingStyle.fill, double stroke = 1}) => Paint()
    ..color = c
    ..style = style
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size s) {
    switch (template.id) {
      case 'base':
        _base(canvas, s);
        break;
      case 'potw':
        _pot(canvas, s, const Color(0xFF00FF37), const Color(0xFF05200E));
        break;
      case 'potm':
        _pot(canvas, s, const Color(0xFF8A27FF), const Color(0xFF150723));
        break;
      case 'epic1':
        _epicGoldTech(canvas, s, const Color(0xFF00A982), const Color(0xFF064239));
        break;
      case 'showtime':
        _showtime(canvas, s);
        break;
      case 'epic2a':
        _epicX(canvas, s, const Color(0xFF0ECC61), const Color(0xFF0B2335));
        break;
      case 'epic2b':
        _epicX(canvas, s, const Color(0xFF00D65A), const Color(0xFF123618));
        break;
      case 'bt1':
        _bigTimeFire(canvas, s);
        break;
      case 'bt2':
        _bigTimeGold(canvas, s);
        break;
      case 'bt3':
        _bigTimeBlue(canvas, s);
        break;
      case 'bt4':
        _bigTimeClock(canvas, s, const Color(0xFFB35D14));
        break;
      case 'bt5':
        _bigTimeVortex(canvas, s);
        break;
      case 'legendary':
        _legendary(canvas, s);
        break;
      case 'oldbt':
        _bigTimeClock(canvas, s, const Color(0xFFE35B18));
        break;
      default:
        _base(canvas, s);
    }
  }

  void _frame(Canvas c, Size s, Color outer, Color inner) {
    c.drawRect(Offset.zero & s, _paint(outer));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .025, s.height * .012, s.width * .95, s.height * .976), Radius.circular(s.width * .025)),
      _paint(inner, style: PaintingStyle.stroke, stroke: s.width * .012),
    );
  }

  void _base(Canvas c, Size s) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF130B1C), Color(0xFF101713), Color(0xFF172718), Color(0xFF090909)],
      ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    final center = Offset(s.width * .50, s.height * .46);
    final rect = Rect.fromCenter(center: center, width: s.width * 1.20, height: s.width * 1.20);
    const colors = [Color(0xFFCE2E32), Color(0xFFE29A20), Color(0xFF2E6DAA), Color(0xFF2E7F49), Color(0xFF51266E)];
    var start = -.9;
    for (var i = 0; i < colors.length; i++) {
      c.drawArc(rect, start, .8, false, _paint(colors[i].withValues(alpha: .78), style: PaintingStyle.stroke, stroke: s.width * .10));
      start += 1.1;
    }
    c.drawCircle(center, s.width * .39, _paint(Colors.black.withValues(alpha: .38)));
    _frame(c, s, const Color(0xFF171717), Colors.white38);
  }

  void _pot(Canvas c, Size s, Color accent, Color base) {
    c.drawRect(Offset.zero & s, _paint(base));
    final g = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, accent.withValues(alpha: .28), Colors.black87])
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, g);
    final p = _paint(accent.withValues(alpha: .82), style: PaintingStyle.stroke, stroke: s.width * .035);
    for (var y = -.05; y < 1.2; y += .18) {
      final path = Path()
        ..moveTo(s.width * .67, s.height * y)
        ..lineTo(s.width * .85, s.height * (y + .07))
        ..lineTo(s.width * .72, s.height * (y + .16));
      c.drawPath(path, p);
    }
    c.drawRect(Rect.fromLTWH(0, s.height * .67, s.width, s.height * .12), _paint(Colors.black.withValues(alpha: .80)));
    _frame(c, s, accent, accent.withValues(alpha: .45));
  }

  void _epicGoldTech(Canvas c, Size s, Color accent, Color base) {
    final bg = Paint()
      ..shader = LinearGradient(colors: [base, const Color(0xFF004D49), const Color(0xFF071316)], begin: Alignment.topLeft, end: Alignment.bottomRight)
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    final p = _paint(accent.withValues(alpha: .42), style: PaintingStyle.stroke, stroke: s.width * .018);
    for (var i = 0; i < 8; i++) {
      final inset = s.width * (.03 + i * .035);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(inset, s.height * .08 + inset, s.width - inset * 2, s.height * .72 - inset), Radius.circular(s.width * .08)), p);
    }
    for (var i = 0; i < 7; i++) {
      final x = s.width * (i / 6);
      c.drawLine(Offset(x, s.height * .66), Offset(s.width * .5, s.height * .40), _paint(Colors.cyanAccent.withValues(alpha: .12), stroke: 1));
    }
    _frame(c, s, const Color(0xFF8C6A32), const Color(0xFFD8B86B));
  }

  void _showtime(Canvas c, Size s) {
    final bg = Paint()
      ..shader = const RadialGradient(center: Alignment(.2, -.3), radius: 1.1, colors: [Color(0xFF1FD4E7), Color(0xFF432A8C), Color(0xFF100D1B)])
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    final p = _paint(const Color(0xFF8A32FF).withValues(alpha: .70), style: PaintingStyle.stroke, stroke: s.width * .035);
    for (var i = 0; i < 5; i++) {
      final y = s.height * (.10 + i * .17);
      final path = Path()
        ..moveTo(s.width * .65, y)
        ..lineTo(s.width * .86, y + s.height * .06)
        ..lineTo(s.width * .73, y + s.height * .14);
      c.drawPath(path, p);
    }
    final bolt = _paint(Colors.cyanAccent.withValues(alpha: .45), style: PaintingStyle.stroke, stroke: s.width * .02);
    for (var i = 0; i < 5; i++) {
      final x = s.width * (.12 + i * .19);
      c.drawLine(Offset(x, s.height * .18), Offset(x + s.width * .14, s.height * .80), bolt);
    }
    _frame(c, s, const Color(0xFF5420A8), const Color(0xFF42D7E8));
  }

  void _epicX(Canvas c, Size s, Color green, Color dark) {
    final bg = Paint()
      ..shader = LinearGradient(colors: [dark, const Color(0xFF071319), green.withValues(alpha: .35)], begin: Alignment.topLeft, end: Alignment.bottomRight)
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    final p = _paint(green.withValues(alpha: .72), style: PaintingStyle.stroke, stroke: s.width * .055);
    for (var i = 0; i < 3; i++) {
      final off = s.width * i * .15;
      c.drawLine(Offset(s.width * .12 + off, s.height * .12), Offset(s.width * .88 - off, s.height * .84), p);
      c.drawLine(Offset(s.width * .88 - off, s.height * .12), Offset(s.width * .12 + off, s.height * .84), p);
    }
    _frame(c, s, const Color(0xFF8B6A34), green);
  }

  void _bigTimeFire(Canvas c, Size s) {
    final bg = Paint()
      ..shader = const RadialGradient(center: Alignment(.2, -.6), radius: 1.1, colors: [Color(0xFFFFD449), Color(0xFFB64005), Color(0xFF120A05)])
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi / 9;
      final center = Offset(s.width * .5, s.height * .42);
      c.drawLine(center, center + Offset(math.cos(angle) * s.width, math.sin(angle) * s.height), _paint(Colors.orangeAccent.withValues(alpha: .16), stroke: s.width * .025));
    }
    _frame(c, s, const Color(0xFF7C5A25), const Color(0xFFF0B43F));
  }

  void _bigTimeGold(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _paint(const Color(0xFF130D08)));
    final center = Offset(s.width * .52, s.height * .42);
    for (var i = 0; i < 5; i++) {
      c.drawCircle(center, s.width * (.26 + i * .09), _paint(Color.lerp(const Color(0xFF5B3B13), const Color(0xFFE7B748), i / 4)!.withValues(alpha: .72), style: PaintingStyle.stroke, stroke: s.width * .055));
    }
    for (var i = 0; i < 24; i++) {
      final a = 2 * math.pi * i / 24;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * s.width * .37;
      final p2 = center + Offset(math.cos(a), math.sin(a)) * s.width * .48;
      c.drawLine(p1, p2, _paint(const Color(0xFFD2A249).withValues(alpha: .45), stroke: s.width * .018));
    }
    _frame(c, s, const Color(0xFF7E5A1F), const Color(0xFFE2B653));
  }

  void _bigTimeBlue(Canvas c, Size s) {
    final bg = Paint()
      ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF02113A), Color(0xFF0B4EA4), Color(0xFF0D1E59)])
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    final p = _paint(Colors.lightBlueAccent.withValues(alpha: .38), style: PaintingStyle.stroke, stroke: s.width * .025);
    for (var i = 0; i < 8; i++) {
      c.drawArc(Rect.fromCenter(center: Offset(s.width * .53, s.height * .45), width: s.width * (1 + i * .08), height: s.height * (.7 + i * .05)), -.8, 1.7, false, p);
    }
    _frame(c, s, const Color(0xFF836721), const Color(0xFFD3B34C));
  }

  void _bigTimeClock(Canvas c, Size s, Color accent) {
    c.drawRect(Offset.zero & s, _paint(const Color(0xFF17120E)));
    final center = Offset(s.width * .50, s.height * .43);
    for (var i = 0; i < 4; i++) {
      c.drawCircle(center, s.width * (.27 + i * .09), _paint(i.isEven ? const Color(0xFF8D7657) : const Color(0xFF2D2C2C), style: PaintingStyle.stroke, stroke: s.width * .055));
    }
    for (var i = 0; i < 30; i++) {
      final a = 2 * math.pi * i / 30;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * s.width * .34;
      final p2 = center + Offset(math.cos(a), math.sin(a)) * s.width * .42;
      c.drawLine(p1, p2, _paint(accent.withValues(alpha: .70), stroke: s.width * .018));
    }
    _frame(c, s, const Color(0xFF8A692E), accent);
  }

  void _bigTimeVortex(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _paint(const Color(0xFF150D05)));
    final center = Offset(s.width * .56, s.height * .43);
    for (var i = 0; i < 16; i++) {
      final rect = Rect.fromCenter(center: center, width: s.width * (1.05 - i * .045), height: s.width * (.86 - i * .035));
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(i * .11);
      c.translate(-center.dx, -center.dy);
      c.drawArc(rect, -.5, 2.9, false, _paint(const Color(0xFFD18B18).withValues(alpha: .55), style: PaintingStyle.stroke, stroke: s.width * .035));
      c.restore();
    }
    _frame(c, s, const Color(0xFF8A5C22), const Color(0xFFDA8D21));
  }

  void _legendary(Canvas c, Size s) {
    final bg = Paint()
      ..shader = const RadialGradient(center: Alignment(0, -.12), radius: .9, colors: [Color(0xFFB8944A), Color(0xFF4A391D), Color(0xFF16120B)])
          .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, bg);
    final center = Offset(s.width * .50, s.height * .42);
    for (var i = 0; i < 26; i++) {
      final a = 2 * math.pi * i / 26;
      c.drawLine(center, center + Offset(math.cos(a) * s.width, math.sin(a) * s.height), _paint(Colors.amberAccent.withValues(alpha: .10), stroke: s.width * .025));
    }
    c.drawCircle(center, s.width * .38, _paint(Colors.black.withValues(alpha: .22)));
    _frame(c, s, const Color(0xFF866923), const Color(0xFFE0BF62));
  }

  @override
  bool shouldRepaint(covariant _TemplateBackgroundPainter oldDelegate) => oldDelegate.template.id != template.id;
}

class _TemplateOverlayPainter extends CustomPainter {
  _TemplateOverlayPainter({required this.template});
  final CardTemplate template;

  @override
  void paint(Canvas canvas, Size s) {
    if (template.id == 'potw' || template.id == 'potm') {
      final accent = template.id == 'potw' ? const Color(0xFF00FF37) : const Color(0xFF8A27FF);
      final p = Paint()
        ..color = accent.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .035
        ..strokeCap = StrokeCap.round;
      for (var y = -.05; y < 1.2; y += .18) {
        final path = Path()
          ..moveTo(s.width * .67, s.height * y)
          ..lineTo(s.width * .85, s.height * (y + .07))
          ..lineTo(s.width * .72, s.height * (y + .16));
        canvas.drawPath(path, p);
      }
      canvas.drawRect(Rect.fromLTWH(0, s.height * .67, s.width, s.height * .12), Paint()..color = Colors.black.withValues(alpha: .75));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .015, s.height * .008, s.width * .97, s.height * .984), Radius.circular(s.width * .02)),
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * .012,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TemplateOverlayPainter oldDelegate) => oldDelegate.template.id != template.id;
}
