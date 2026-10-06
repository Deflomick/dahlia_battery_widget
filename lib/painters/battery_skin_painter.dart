import 'package:flutter/material.dart';
import '../enums/battery_skin.dart';

/// Painter per il disegno delle skin vettoriali della batteria.
class BatterySkinPainter extends CustomPainter {
  final BatterySkin skin;
  final int level;

  const BatterySkinPainter({
    required this.skin,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = level >= 40 ? Colors.greenAccent : Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = size.center(Offset.zero);

    if (skin == BatterySkin.neon) {
      canvas.drawCircle(center, size.width / 2 - 5, paint);
      paint.color = paint.color.withOpacity(0.3);
      paint.strokeWidth = 6;
      canvas.drawCircle(center, size.width / 2 - 5, paint);
    } else if (skin == BatterySkin.classic) {
      final rect = Rect.fromLTWH(15, 25, size.width - 35, size.height - 50);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
      canvas.drawRect(Rect.fromLTWH(size.width - 20, 35, 5, 10), paint);
    } else if (skin == BatterySkin.minimal) {
      final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
      canvas.drawArc(rect, -1.57, (level / 100) * 6.28, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BatterySkinPainter oldDelegate) {
    return oldDelegate.skin != skin || oldDelegate.level != level;
  }
}
