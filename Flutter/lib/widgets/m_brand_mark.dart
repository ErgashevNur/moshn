import 'package:flutter/material.dart';
import 'dart:math' as math;

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(color: color),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final innerR = r * 0.52;
    final spokeOuter = r * 0.92;
    final spokeInner = innerR * 1.1;

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), r * 0.92, outerPaint);

    // Inner circle
    canvas.drawCircle(Offset(cx, cy), innerR, outerPaint);

    // Cardinal spokes (N/S/E/W) — full opacity
    final cardinalPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      canvas.drawLine(
        Offset(cx + spokeInner * math.cos(angle), cy + spokeInner * math.sin(angle)),
        Offset(cx + spokeOuter * math.cos(angle), cy + spokeOuter * math.sin(angle)),
        cardinalPaint,
      );
    }

    // Diagonal spokes (NE/NW/SE/SW) — 50% opacity
    final diagPaint = Paint()
      ..color = color.withAlpha(128)
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 4;
      canvas.drawLine(
        Offset(cx + spokeInner * math.cos(angle), cy + spokeInner * math.sin(angle)),
        Offset(cx + spokeOuter * math.cos(angle), cy + spokeOuter * math.sin(angle)),
        diagPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
