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

/// Painter che disegna l'aura colorata attorno all'immagine Dahlia.
///
/// Usa [MaskFilter.blur] (primitiva Skia nativa) invece di [BoxShadow] o
/// [RadialGradient], perché funziona correttamente nel renderer off-screen
/// di [HomeWidget.renderFlutterWidget] e produce l'alone anche nella bitmap
/// del widget Android.
///
/// Il cerchio viene disegnato esattamente al bordo esterno dell'immagine
/// (raggio = size × 0.40, dato che l'immagine occupa size × 0.8 = 80% del container),
/// e il blur gaussiano lo espande come alone attorno ad esso.
class _GlowPainter extends CustomPainter {
  final int batteryLevel;

  const _GlowPainter({required this.batteryLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final Color glowColor = batteryLevel >= 80
        ? Colors.greenAccent
        : (batteryLevel >= 40 ? Colors.yellowAccent : Colors.redAccent);

    final center = size.center(Offset.zero);

    // L'immagine Dahlia è size*0.8 wide → il suo raggio = size*0.40.
    // Disegnare il cerchio su quel raggio con blur gaussiano produce
    // un alone che si espande verso l'interno e verso l'esterno dell'immagine.
    final imageRadius = size.shortestSide * 0.40;

    final paint = Paint()
      ..color = glowColor.withOpacity(0.90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawCircle(center, imageRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.batteryLevel != batteryLevel;
}
