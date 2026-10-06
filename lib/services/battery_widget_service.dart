import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:home_widget/home_widget.dart';
import '../models/battery_data.dart';

/// Servizio Singleton per la gestione e il monitoraggio dei dati della batteria
/// e la sincronizzazione con i widget della Home Screen di Android.
class BatteryWidgetService {
  static final BatteryWidgetService _instance =
      BatteryWidgetService._internal();
  factory BatteryWidgetService() => _instance;
  BatteryWidgetService._internal();

  // Chiavi condivise con SharedPreferences / HomeWidget
  static const String keyLevel = 'level_v2';
  static const String keyTemp = 'temp_v2';
  static const String keyCharging = 'charging_v2';
  static const String keyVoltage = 'voltage_v2';
  static const String keyHealth = 'health_v2';
  static const String keyImage = 'battery_image';
  static const String keySelectedSkin = 'selected_skin';

  /// Nomi di tutti gli AppWidgetProvider registrati nel manifest Android.
  static const List<String> androidWidgetNames = [
    'BatteryWidgetProvider',
    'BatteryWidgetCompactProvider',
    'BatteryWidgetHorizontalProvider',
  ];

  static const MethodChannel _channel =
      MethodChannel('com.example.mdfy_theme/battery');
  final Battery _battery = Battery();

  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _periodicTimer;
  StreamSubscription<BatteryData>? _periodicUpdateSubscription;

  final StreamController<BatteryData> _dataController =
      StreamController<BatteryData>.broadcast();

  /// Stream broadcast che emette un nuovo [BatteryData] ad ogni variazione o tick periodico.
  Stream<BatteryData> get batteryStream => _dataController.stream;

  /// Aggiorna tutti i widget provider registrati su Android.
  Future<void> updateAllHomeWidgets() async {
    for (final name in androidWidgetNames) {
      try {
        await HomeWidget.updateWidget(androidName: name);
      } catch (e) {
        debugPrint("Errore aggiornamento widget $name: $e");
      }
    }
  }

  /// Converte la temperatura da Celsius a Fahrenheit se [isFahrenheit] è true.
  static double convertTemperature(double celsius,
      {bool isFahrenheit = false}) {
    if (!isFahrenheit) return celsius;
    return (celsius * 9 / 5) + 32;
  }

  /// Aggiorna i dati e l'aspetto visivo dei widget nella Home Screen.
  Future<void> updateBatteryWidget({
    Widget? customImageWidget,
    double? temp,
    bool isFahrenheit = false,
    bool? isCharging,
    double? voltage,
    String? health,
  }) async {
    try {
      final int level = await getCurrentLevel();
      await HomeWidget.saveWidgetData<int>(keyLevel, level);

      if (temp != null) {
        final double displayTemp =
            convertTemperature(temp, isFahrenheit: isFahrenheit);
        final String unit = isFahrenheit ? "°F" : "°C";
        await HomeWidget.saveWidgetData<String>(
          keyTemp,
          "${displayTemp.toStringAsFixed(1)}$unit",
        );
      }

      if (isCharging != null) {
        await HomeWidget.saveWidgetData<bool>(keyCharging, isCharging);
      }

      if (voltage != null) {
        await HomeWidget.saveWidgetData<String>(
          keyVoltage,
          "${voltage.toStringAsFixed(2)} V",
        );
      }

      if (health != null) {
        await HomeWidget.saveWidgetData<String>(keyHealth, health);
      }

      if (customImageWidget != null) {
        await HomeWidget.renderFlutterWidget(
          customImageWidget,
          key: keyImage,
          logicalSize: const Size(200, 200),
        );
      }

      await updateAllHomeWidgets();
    } catch (e) {
      debugPrint("Errore aggiornamento widget: $e");
    }
  }

  /// Restituisce la percentuale attuale della batteria (0-100).
  Future<int> getCurrentLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      debugPrint("Errore lettura batteryLevel: $e");
      return 0;
    }
  }

  /// Recupera informazioni diagnostiche dettagliate dal canale nativo Android.
  Future<Map<String, dynamic>> getExtraInfo() async {
    try {
      final dynamic result =
          await _channel.invokeMethod('getBatteryExtraInfo').timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
      return result != null ? Map<String, dynamic>.from(result) : {};
    } catch (e) {
      debugPrint("Errore lettura getBatteryExtraInfo: $e");
      return {};
    }
  }

  /// Formatta i millisecondi di carica rimanente in una stringa leggibile (es: "2h 30m" o "45m").
  /// Restituisce "--" per valori nulli, non validi o negativi.
  static String formatDuration(int millis) {
    if (millis <= 0) return "--";
    final Duration duration = Duration(milliseconds: millis);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";
  }

  /// Metodo istanza compatibile per la formattazione del tempo.
  String formatTime(int millis) => formatDuration(millis);

  /// Avvia il monitoraggio attivo della batteria se non già avviato.
  void startMonitoring() {
    if (_batterySubscription != null) return;

    _checkNowAndEmit();

    _batterySubscription = _battery.onBatteryStateChanged.listen(
      (_) => _checkNowAndEmit(),
      onError: (error) => debugPrint("Errore onBatteryStateChanged: $error"),
    );

    _periodicTimer?.cancel();
    _periodicTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _checkNowAndEmit());
  }

  /// Interrompe il monitoraggio attivo e libera i timer.
  void stopMonitoring() {
    _batterySubscription?.cancel();
    _batterySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _periodicUpdateSubscription?.cancel();
    _periodicUpdateSubscription = null;
  }

  /// Rilascia le risorse attive senza invalidare l'istanza Singleton.
  void dispose() {
    stopMonitoring();
  }

  Future<void> _checkNowAndEmit() async {
    try {
      final level = await getCurrentLevel();
      final state = await _battery.batteryState;
      final extra = await getExtraInfo();
      final data = BatteryData(level: level, state: state, extra: extra);
      if (!_dataController.isClosed) {
        _dataController.add(data);
      }
    } catch (e) {
      debugPrint("Errore monitoraggio: $e");
    }
  }

  /// Registra una callback periodica e restituisce la subscription per eventuale cancellazione.
  StreamSubscription<BatteryData> startPeriodicUpdate(
    Function(int level, BatteryState state, Map<String, dynamic> extra)
        callback,
  ) {
    startMonitoring();
    _periodicUpdateSubscription?.cancel();
    final sub = batteryStream
        .listen((data) => callback(data.level, data.state, data.extra));
    _periodicUpdateSubscription = sub;
    return sub;
  }
}
