import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:home_widget/home_widget.dart';

/// Rappresenta lo stato completo della batteria in un determinato momento.
class BatteryData {
  final int level;
  final BatteryState state;
  final Map<String, dynamic> extra;

  BatteryData({
    required this.level,
    required this.state,
    required this.extra,
  });

  bool get isCharging => state == BatteryState.charging;
}

/// Servizio Singleton per la gestione e il monitoraggio dei dati della batteria.
class BatteryWidgetService {
  static final BatteryWidgetService _instance = BatteryWidgetService._internal();
  factory BatteryWidgetService() => _instance;
  BatteryWidgetService._internal();

  static const String keyLevel = 'level_v2';
  static const String keyTemp = 'temp_v2';
  static const String keyCharging = 'charging_v2';
  static const String keyVoltage = 'voltage_v2';
  static const String keyHealth = 'health_v2';
  static const String keyImage = 'battery_image';

  static const String _androidWidgetName = 'BatteryWidgetProvider';
  static const String _androidWidgetCompactName = 'BatteryWidgetCompactProvider';
  static const String _androidWidgetHorizontalName = 'BatteryWidgetHorizontalProvider';

  static const MethodChannel _channel = MethodChannel('com.example.mdfy_theme/battery');
  final Battery _battery = Battery();

  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _periodicTimer;

  final StreamController<BatteryData> _dataController = StreamController<BatteryData>.broadcast();
  Stream<BatteryData> get batteryStream => _dataController.stream;

  /// Aggiorna i dati e l'aspetto visivo del widget nella Home Screen.
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
        final double displayTemp = isFahrenheit ? (temp * 9 / 5) + 32 : temp;
        final String unit = isFahrenheit ? "°F" : "°C";
        await HomeWidget.saveWidgetData<String>(keyTemp, "${displayTemp.toStringAsFixed(1)}$unit");
      }
      
      if (isCharging != null) {
        await HomeWidget.saveWidgetData<bool>(keyCharging, isCharging);
      }

      if (voltage != null) {
        await HomeWidget.saveWidgetData<String>(keyVoltage, "${voltage.toStringAsFixed(2)} V");
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
      
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
      await HomeWidget.updateWidget(androidName: _androidWidgetCompactName);
      await HomeWidget.updateWidget(androidName: _androidWidgetHorizontalName);
    } catch (e) {
      debugPrint("Errore aggiornamento widget: $e");
    }
  }

  Future<int> getCurrentLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> getExtraInfo() async {
    try {
      final dynamic result = await _channel.invokeMethod('getBatteryExtraInfo').timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      return result != null ? Map<String, dynamic>.from(result) : {};
    } catch (e) {
      return {};
    }
  }

  String formatTime(int millis) {
    if (millis <= 0) return "--";
    final Duration duration = Duration(milliseconds: millis);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";
  }

  void startMonitoring() {
    if (_batterySubscription != null) return;

    _checkNowAndEmit();

    _batterySubscription = _battery.onBatteryStateChanged.listen((_) => _checkNowAndEmit());
    
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkNowAndEmit());
  }

  void stopMonitoring() {
    _batterySubscription?.cancel();
    _batterySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> _checkNowAndEmit() async {
    try {
      final level = await getCurrentLevel();
      final state = await _battery.batteryState;
      final extra = await getExtraInfo();
      final data = BatteryData(level: level, state: state, extra: extra);
      _dataController.add(data);
    } catch (e) {
      debugPrint("Errore monitoraggio: $e");
    }
  }

  void startPeriodicUpdate(Function(int level, BatteryState state, Map<String, dynamic> extra) callback) {
    startMonitoring();
    batteryStream.listen((data) => callback(data.level, data.state, data.extra));
  }
}
