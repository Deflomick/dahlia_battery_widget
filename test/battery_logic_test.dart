import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahlia_battery_widget/enums/battery_skin.dart';
import 'package:dahlia_battery_widget/models/battery_data.dart';
import 'package:dahlia_battery_widget/painters/battery_skin_painter.dart';
import 'package:dahlia_battery_widget/services/battery_widget_service.dart';

void main() {
  group('BatteryWidgetService Pure Helpers', () {
    test('formatDuration formats remaining charge time correctly', () {
      // Valori non validi o negativi/zero
      expect(BatteryWidgetService.formatDuration(-1), equals('--'));
      expect(BatteryWidgetService.formatDuration(0), equals('--'));

      // Meno di un'ora: 45 minuti
      const fortyFiveMinutesMs = 45 * 60 * 1000;
      expect(
        BatteryWidgetService.formatDuration(fortyFiveMinutesMs),
        equals('45m'),
      );

      // Più di un'ora: 2 ore e 15 minuti
      const twoHoursFifteenMs = (2 * 60 + 15) * 60 * 1000;
      expect(
        BatteryWidgetService.formatDuration(twoHoursFifteenMs),
        equals('2h 15m'),
      );
    });

    test('convertTemperature converts Celsius to Fahrenheit accurately', () {
      // Quando isFahrenheit è false, mantiene Celsius invariato
      expect(
        BatteryWidgetService.convertTemperature(25.0, isFahrenheit: false),
        equals(25.0),
      );

      // Quando isFahrenheit è true, applica la formula (C * 9 / 5) + 32
      expect(
        BatteryWidgetService.convertTemperature(0.0, isFahrenheit: true),
        equals(32.0),
      );
      expect(
        BatteryWidgetService.convertTemperature(100.0, isFahrenheit: true),
        equals(212.0),
      );
      expect(
        BatteryWidgetService.convertTemperature(25.0, isFahrenheit: true),
        equals(77.0),
      );
    });
  });

  group('BatteryData Model', () {
    test('isCharging and safe fallback getters work as expected', () {
      const chargingData = BatteryData(
        level: 85,
        state: BatteryState.charging,
        extra: {
          'temperature': 34.5,
          'voltage': 4.12,
          'health': 'Buona',
          'technology': 'Li-ion',
          'chargeTimeRemaining': 1800000,
        },
      );

      expect(chargingData.isCharging, isTrue);
      expect(chargingData.temperature, equals(34.5));
      expect(chargingData.voltage, equals(4.12));
      expect(chargingData.health, equals('Buona'));
      expect(chargingData.technology, equals('Li-ion'));
      expect(chargingData.chargeTimeRemaining, equals(1800000));

      const emptyExtraData = BatteryData(
        level: 20,
        state: BatteryState.discharging,
        extra: {},
      );

      expect(emptyExtraData.isCharging, isFalse);
      expect(emptyExtraData.temperature, equals(0.0));
      expect(emptyExtraData.voltage, equals(0.0));
      expect(emptyExtraData.health, equals('Buona'));
      expect(emptyExtraData.technology, equals('Li-ion'));
      expect(emptyExtraData.chargeTimeRemaining, equals(-1));
    });
  });

  group('Dahlia Skin Asset & Painter Optimization', () {
    test(
        'getDahliaAssetPath selects corresponding asset according to battery thresholds',
        () {
      // < 40% -> low
      expect(getDahliaAssetPath(0), equals('assets/images/dahlia_low.png'));
      expect(getDahliaAssetPath(39), equals('assets/images/dahlia_low.png'));

      // 40% - 79% -> mid
      expect(getDahliaAssetPath(40), equals('assets/images/dahlia_mid.png'));
      expect(getDahliaAssetPath(79), equals('assets/images/dahlia_mid.png'));

      // >= 80% -> high
      expect(getDahliaAssetPath(80), equals('assets/images/dahlia_high.png'));
      expect(getDahliaAssetPath(100), equals('assets/images/dahlia_high.png'));
    });

    test('BatterySkinPainter shouldRepaint evaluates state equality correctly',
        () {
      const painter1 =
          BatterySkinPainter(skin: BatterySkin.theDahlia, level: 50);
      const painterSame =
          BatterySkinPainter(skin: BatterySkin.theDahlia, level: 50);
      const painterDifferentLevel =
          BatterySkinPainter(skin: BatterySkin.theDahlia, level: 51);
      const painterDifferentSkin =
          BatterySkinPainter(skin: BatterySkin.neon, level: 50);

      expect(painter1.shouldRepaint(painterSame), isFalse);
      expect(painter1.shouldRepaint(painterDifferentLevel), isTrue);
      expect(painter1.shouldRepaint(painterDifferentSkin), isTrue);
    });
  });
}
