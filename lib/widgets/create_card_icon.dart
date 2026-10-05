import 'package:flutter/material.dart';

class CreateCardIcon extends StatelessWidget {
  const CreateCardIcon({super.key, this.size = 34, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CreateCardIconPainter(c)),
    );
  }
}

class _CreateCardIconPainter extends CustomPainter {
  _CreateCardIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * .08, s.height * .10, s.width * .62, s.height * .76),
      Radius.circular(s.width * .11),
    );
    canvas.drawRRect(card, stroke);
    canvas.drawLine(Offset(s.width * .17, s.height * .28), Offset(s.width * .57, s.height * .28), stroke);
    canvas.drawCircle(Offset(s.width * .38, s.height * .48), s.width * .08, stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(s.width * .38, s.height * .66), width: s.width * .28, height: s.height * .20),
      3.35,
      2.75,
      false,
      stroke,
    );
    canvas.drawLine(Offset(s.width * .76, s.height * .64), Offset(s.width * .76, s.height * .93), stroke);
    canvas.drawLine(Offset(s.width * .62, s.height * .785), Offset(s.width * .90, s.height * .785), stroke);
  }

  @override
  bool shouldRepaint(covariant _CreateCardIconPainter oldDelegate) => oldDelegate.color != color;
}
