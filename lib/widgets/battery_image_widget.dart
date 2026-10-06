import 'package:flutter/material.dart';
import '../enums/battery_skin.dart';
import '../painters/battery_skin_painter.dart';

/// Widget che genera l'aspetto grafico della batteria,
/// utilizzato sia per l'anteprima nella dashboard sia per il rendering delle bitmap del widget Android.
class BatteryImageWidget extends StatelessWidget {
  final BatterySkin selectedSkin;
  final int batteryLevel;
  final bool enableGlow;
  final double size;

  const BatteryImageWidget({
    super.key,
    required this.selectedSkin,
    required this.batteryLevel,
    this.enableGlow = true,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSkin == BatterySkin.theDahlia) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (enableGlow)
              Positioned.fill(
                child: CustomPaint(
                  painter: _GlowPainter(batteryLevel: batteryLevel),
                ),
              ),
            Center(
              child: Image.asset(
                getDahliaAssetPath(batteryLevel),
                width: size * 0.8,
                height: size * 0.8,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: BatterySkinPainter(
          skin: selectedSkin,
          level: batteryLevel,
        ),
        child: const Center(
          child: Icon(Icons.bolt, color: Colors.white54, size: 60),
        ),
      ),
    );
  }
}

/// Painter che disegna l'aura colorata con un [RadialGradient] all'interno dei bounds del widget.
///
/// A differenza di [BoxShadow] (che emette luce fuori dai bounds e viene clippata da
/// [HomeWidget.renderFlutterWidget]), il gradiente radiale rimane entro il rettangolo
/// del canvas e viene correttamente incluso nella bitmap del widget Android.
class _GlowPainter extends CustomPainter {
  final int batteryLevel;

  const _GlowPainter({required this.batteryLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final Color glowColor = batteryLevel >= 80
        ? Colors.greenAccent
        : (batteryLevel >= 40 ? Colors.yellowAccent : Colors.redAccent);

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Gradiente ad anello: trasparente al centro (coperto dall'immagine),
    // picco di luminosità attorno al bordo esterno dell'immagine (~55-75% del raggio),
    // poi sfuma verso trasparente al bordo esterno del cerchio.
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          glowColor.withOpacity(0.75),
          glowColor.withOpacity(0.55),
          glowColor.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 0.55, 0.68, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.batteryLevel != batteryLevel;
}
