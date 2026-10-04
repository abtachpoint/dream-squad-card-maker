import 'dart:io';
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

  Widget _assetOrPlaceholder(String? path, IconData icon, String label) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.black.withOpacity(.24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: compact ? 16 : 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: compact ? 7 : 10, color: Colors.white70, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String?>.generate(template.photoSlots, (i) => i < photoPaths.length ? photoPaths[i] : null);
    final border = template.pack == CardPack.bigTime
        ? const Color(0xFFC49A47)
        : template.pack == CardPack.premium
            ? const Color(0xFF7A66FF)
            : const Color(0xFFB5B5B5);

    return AspectRatio(
      aspectRatio: 0.69,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 10 : 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: border, width: compact ? 1.5 : 2.4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: template.colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!template.backgroundLocked && customBackgroundPath != null && File(customBackgroundPath!).existsSync())
                Image.file(File(customBackgroundPath!), fit: BoxFit.cover),
              Positioned.fill(
                child: CustomPaint(painter: _DecorPainter(template: template)),
              ),
              if (template.photoSlots >= 1)
                Positioned(
                  top: compact ? 20 : 34,
                  left: compact ? 42 : 74,
                  right: compact ? 8 : 14,
                  bottom: compact ? 48 : 78,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 8 : 16),
                    child: _assetOrPlaceholder(photos[0], Icons.person_add_alt_1, 'PHOTO 1'),
                  ),
                ),
              if (template.photoSlots >= 2)
                Positioned(
                  left: compact ? 18 : 30,
                  bottom: compact ? 50 : 82,
                  width: compact ? 54 : 95,
                  height: compact ? 74 : 132,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 7 : 12),
                    child: _assetOrPlaceholder(photos[1], Icons.person_add_alt_1, 'PHOTO 2'),
                  ),
                ),
              if (template.photoSlots >= 3)
                Positioned(
                  right: compact ? 10 : 18,
                  bottom: compact ? 48 : 80,
                  width: compact ? 48 : 84,
                  height: compact ? 64 : 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 7 : 12),
                    child: _assetOrPlaceholder(photos[2], Icons.person_add_alt_1, 'PHOTO 3'),
                  ),
                ),
              if (template.photoSlots >= 4)
                Positioned(
                  left: compact ? 58 : 102,
                  bottom: compact ? 46 : 76,
                  width: compact ? 44 : 78,
                  height: compact ? 60 : 106,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 7 : 12),
                    child: _assetOrPlaceholder(photos[3], Icons.person_add_alt_1, 'PHOTO 4'),
                  ),
                ),
              Positioned(
                left: compact ? 8 : 14,
                top: compact ? 8 : 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$rating', style: TextStyle(fontSize: compact ? 26 : 48, height: .92, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text(position, style: TextStyle(fontSize: compact ? 13 : 24, height: 1, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
              Positioned(
                left: compact ? 8 : 14,
                top: compact ? 60 : 108,
                width: compact ? 34 : 58,
                height: compact ? 34 : 58,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 7 : 10),
                  child: _assetOrPlaceholder(logoPath, Icons.shield_outlined, 'LOGO'),
                ),
              ),
              Positioned(
                left: compact ? 8 : 14,
                top: compact ? 98 : 172,
                width: compact ? 34 : 58,
                height: compact ? 24 : 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 5 : 8),
                  child: _assetOrPlaceholder(flagPath, Icons.flag_outlined, 'FLAG'),
                ),
              ),
              Positioned(
                left: compact ? 8 : 14,
                right: compact ? 8 : 14,
                bottom: compact ? 18 : 28,
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        playerName.trim().isEmpty ? 'YOUR NAME' : playerName,
                        maxLines: 1,
                        style: TextStyle(fontSize: compact ? 16 : 29, fontWeight: FontWeight.w900, color: Colors.white, shadows: const [Shadow(blurRadius: 6, color: Colors.black)]),
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (_) => Icon(Icons.star_rounded, size: compact ? 12 : 22, color: const Color(0xFFFFE344))),
                    ),
                    if (template.boosterSlots > 0) ...[
                      SizedBox(height: compact ? 2 : 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          template.boosterSlots,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: compact ? 12 : 20,
                            height: compact ? 12 : 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: i == 0 ? Colors.cyanAccent : Colors.white38, width: 1.5),
                              color: Colors.black54,
                            ),
                            child: Icon(Icons.bolt, size: compact ? 8 : 13, color: i == 0 ? Colors.cyanAccent : Colors.white38),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  _DecorPainter({required this.template});
  final CardTemplate template;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .018
      ..color = Colors.white.withOpacity(.16);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .62, size.height * .36), width: size.width * .9, height: size.width * .9), p);
    p.color = Colors.black.withOpacity(.18);
    p.strokeWidth = size.width * .05;
    canvas.drawLine(Offset(0, size.height * .78), Offset(size.width, size.height * .62), p);

    if (template.pack != CardPack.free) {
      p.color = Colors.white.withOpacity(.10);
      p.strokeWidth = size.width * .012;
      for (var i = 0; i < 5; i++) {
        final x = size.width * (.18 + i * .17);
        canvas.drawLine(Offset(x, 0), Offset(x - size.width * .22, size.height), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DecorPainter oldDelegate) => oldDelegate.template.id != template.id;
}
