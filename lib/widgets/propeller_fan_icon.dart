import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';

class PropellerFanIcon extends StatelessWidget {
  final bool active;
  final double size;
  final double shapeScale;
  final Color? color;

  const PropellerFanIcon({
    super.key,
    required this.active,
    this.size = 20,
    this.shapeScale = 1.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (active ? kIotOn : kIotOff);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PropellerFanPainter(
          color: iconColor,
          active: active,
          shapeScale: shapeScale,
        ),
      ),
    );
  }
}

class _PropellerFanPainter extends CustomPainter {
  final Color color;
  final bool active;
  final double shapeScale;

  _PropellerFanPainter({
    required this.color,
    required this.active,
    required this.shapeScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h) * shapeScale.clamp(0.1, 1.0);

    final cx = w / 2;
    final cy = h / 2;

    final outer = s * 0.44;
    final inner = s * 0.14;
    final hubR = s * 0.10;

    // Thickness / blade width controls the visual “leaf” width.
    final bladeSpan = 0.45; // radians (approx)

    final fillOpacity = active ? 1.0 : 0.45;
    final strokeOpacity = active ? 0.95 : 0.75;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(fillOpacity);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withOpacity(strokeOpacity)
      ..strokeWidth = math.max(0.8, s * 0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 5-blade propeller.
    for (int i = 0; i < 5; i++) {
      final angle = (2 * 3.141592653589793 * i / 5);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      final baseAngle = -3.141592653589793 / 2;
      final a1 = baseAngle - bladeSpan / 2;
      final a2 = baseAngle + bladeSpan / 2;

      final p1 = Offset(inner * math.cos(a1), inner * math.sin(a1));
      final p2 = Offset(outer * math.cos(a1), outer * math.sin(a1));
      final p3 = Offset(outer * math.cos(a2), outer * math.sin(a2));
      final p4 = Offset(inner * math.cos(a2), inner * math.sin(a2));

      // “Leaf” shape: curved outward bulge between p2 and p3.
      final mid = Offset(
        outer * 1.02 * math.cos(baseAngle),
        outer * 1.02 * math.sin(baseAngle),
      );
      final ctrl1 = Offset(
        (p1.dx + mid.dx) / 2,
        (p1.dy + mid.dy) / 2,
      );
      final ctrl2 = Offset(
        (p2.dx + mid.dx) / 2,
        (p2.dy + mid.dy) / 2,
      );
      final ctrl3 = Offset(
        (p3.dx + mid.dx) / 2,
        (p3.dy + mid.dy) / 2,
      );

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, p2.dx, p2.dy)
        ..cubicTo(ctrl2.dx, ctrl2.dy, ctrl3.dx, ctrl3.dy, p3.dx, p3.dy)
        ..quadraticBezierTo(
          (p3.dx + p4.dx) / 2,
          (p3.dy + p4.dy) / 2,
          p4.dx,
          p4.dy,
        )
        ..close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);

      canvas.restore();
    }

    // Hub.
    final hubPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = active ? color.withOpacity(0.95) : color.withOpacity(0.55);

    canvas.drawCircle(Offset(cx, cy), hubR, hubPaint);
    canvas.drawCircle(
      Offset(cx, cy),
      hubR,
      strokePaint..strokeWidth = math.max(1.0, s * 0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _PropellerFanPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.active != active;
  }

  
}
