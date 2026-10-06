import 'package:battery_plus/battery_plus.dart';

/// Rappresenta lo stato completo della batteria in un determinato momento.
class BatteryData {
  /// Percentuale di carica attuale (0-100).
  final int level;

  /// Stato di carica (charging, discharging, full, unknown).
  final BatteryState state;

  /// Mappa di parametri extra recuperati dal canale nativo Android.
  final Map<String, dynamic> extra;

  const BatteryData({
    required this.level,
    required this.state,
    required this.extra,
  });

  /// True se il dispositivo è attualmente sotto carica.
  bool get isCharging => state == BatteryState.charging;

  /// Temperatura in gradi Celsius recuperata da Android BatteryManager.
  double get temperature => (extra['temperature'] as num?)?.toDouble() ?? 0.0;

  /// Voltaggio della batteria in Volt.
  double get voltage => (extra['voltage'] as num?)?.toDouble() ?? 0.0;

  /// Stato di salute della batteria (es. 'Buona', 'Surriscaldata').
  String get health => extra['health'] as String? ?? 'Buona';

  /// Tecnologia della batteria (es. 'Li-ion').
  String get technology => extra['technology'] as String? ?? 'Li-ion';

  /// Tempo residuo per la carica completa in millisecondi (-1 se non disponibile).
  int get chargeTimeRemaining =>
      (extra['chargeTimeRemaining'] as num?)?.toInt() ?? -1;
}
