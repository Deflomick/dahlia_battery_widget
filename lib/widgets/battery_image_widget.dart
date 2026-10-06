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
          children: [
            if (enableGlow)
              Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: batteryLevel >= 80
                          ? Colors.greenAccent.withOpacity(0.4)
                          : (batteryLevel >= 40
                              ? Colors.yellowAccent.withOpacity(0.3)
                              : Colors.redAccent.withOpacity(0.4)),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
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
