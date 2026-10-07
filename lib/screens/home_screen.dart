import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as fow;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import '../enums/battery_skin.dart';
import '../models/battery_data.dart';
import '../services/battery_widget_service.dart';
import '../services/foreground_service.dart';
import '../widgets/battery_image_widget.dart';
import '../widgets/diagnostic_card.dart';
import '../widgets/settings_card.dart';

/// Schermo principale (Dashboard) dell'applicazione.
class HomeScreen extends StatefulWidget {
  final String title;
  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _batteryLevel = 0;
  bool _isCharging = false;
  String _remainingTime = "--";
  double _temp = 0.0;
  double _voltage = 0.0;
  String _health = "Buona";
  String _technology = "Li-ion";

  // Impostazioni personalizzate
  bool _isFahrenheit = false;
  bool _enableGlow = true;
  int _alertThreshold = 80; // 0 = Disattivato, 80, 90, 100
  int _refreshIntervalSeconds = 60; // 30, 60, 300, 900

  BatterySkin _selectedSkin = BatterySkin.neon;
  final BatteryWidgetService _batteryService = BatteryWidgetService();
  StreamSubscription<BatteryData>? _batterySubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initBattery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverlayOnBoot();
    });
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOverlayOnBoot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isOverlayActive = prefs.getBool('overlay_active') ?? false;
      final int refreshInterval =
          prefs.getInt('refresh_interval_seconds') ?? 60;

      if (isOverlayActive) {
        await startForegroundService(intervalMs: refreshInterval * 1000);
      }
    } catch (e) {
      debugPrint("Errore ripristino service all'avvio: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bool enableGlow = prefs.getBool('enable_glow') ?? true;
    setState(() {
      _isFahrenheit = prefs.getBool('is_fahrenheit') ?? false;
      _enableGlow = enableGlow;
      _alertThreshold = prefs.getInt('alert_threshold') ?? 80;
      _refreshIntervalSeconds = prefs.getInt('refresh_interval_seconds') ?? 60;
    });
    await HomeWidget.saveWidgetData<bool>('enable_glow', enableGlow);
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
      await HomeWidget.saveWidgetData<bool>(key, value);
    }
    if (value is int) {
      await prefs.setInt(key, value);
      await HomeWidget.saveWidgetData<int>(key, value);
    }

    _updateWidget(silent: true);

    if (key == 'enable_glow' && await fow.FlutterOverlayWindow.isActive()) {
      await fow.FlutterOverlayWindow.shareData({'enableGlow': value});
    }
  }

  Future<void> _changeSkin(BatterySkin skin) async {
    setState(() => _selectedSkin = skin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BatteryWidgetService.keySelectedSkin, skin.name);
    await HomeWidget.saveWidgetData<String>(
      BatteryWidgetService.keySelectedSkin,
      skin.name,
    );

    if (await fow.FlutterOverlayWindow.isActive()) {
      await fow.FlutterOverlayWindow.shareData({'skin': skin.name});
    }
    _updateWidget(silent: true);
  }

  Future<void> _initBattery() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSkin = prefs.getString(BatteryWidgetService.keySelectedSkin);
    if (savedSkin != null) {
      try {
        _selectedSkin = BatterySkin.values.byName(savedSkin);
      } catch (_) {
        _selectedSkin = BatterySkin.neon;
      }
      await HomeWidget.saveWidgetData<String>(
        BatteryWidgetService.keySelectedSkin,
        _selectedSkin.name,
      );
    }

    _batteryService.startMonitoring();
    _batterySubscription = _batteryService.batteryStream.listen((data) {
      if (!mounted) return;

      final bool wasCharging = _isCharging;
      final int oldLevel = _batteryLevel;

      setState(() {
        _batteryLevel = data.level;
        _isCharging = data.isCharging;
        _temp = data.temperature;
        _voltage = data.voltage;
        _health = data.health;
        _technology = data.technology;

        if (_isCharging) {
          final int chargeTime = data.chargeTimeRemaining;
          _remainingTime = "Fine tra ${_batteryService.formatTime(chargeTime)}";
        } else {
          _remainingTime = "Scarica stimata: --";
        }
      });

      // Notifica allarme carica completata
      if (_isCharging &&
          _alertThreshold > 0 &&
          data.level >= _alertThreshold &&
          oldLevel < _alertThreshold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚡ Batteria al $_batteryLevel%! Puoi staccare il caricabatterie.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (wasCharging != _isCharging || oldLevel != _batteryLevel) {
        _updateWidget(silent: true);
      }
    });
  }

  Widget _buildPreviewImage({double size = 160}) {
    return BatteryImageWidget(
      selectedSkin: _selectedSkin,
      batteryLevel: _batteryLevel,
      enableGlow: _enableGlow,
      size: size,
    );
  }

  Future<void> _updateWidget({bool silent = false}) async {
    await _batteryService.updateBatteryWidget(
      customImageWidget: _buildPreviewImage(size: 200),
      temp: _temp,
      isFahrenheit: _isFahrenheit,
      isCharging: _isCharging,
      voltage: _voltage,
      health: _health,
    );
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Widget aggiornato su tutti i formati!')),
      );
    }
  }

  Future<void> _toggleOverlay() async {
    final bool isActive = await fow.FlutterOverlayWindow.isActive();
    final prefs = await SharedPreferences.getInstance();

    if (isActive) {
      await fow.FlutterOverlayWindow.closeOverlay();
      await stopForegroundService();
      await prefs.setBool('overlay_active', false);
      if (mounted) setState(() {});
      return;
    }

    final bool status = await fow.FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await fow.FlutterOverlayWindow.requestPermission();
      return;
    }

    await startForegroundService(intervalMs: _refreshIntervalSeconds * 1000);

    await fow.FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Batteria Custom",
      overlayContent: "Monitoraggio batteria attivo",
      width: fow.WindowSize.matchParent,
      height: 150,
      alignment: fow.OverlayAlignment.topCenter,
      visibility: fow.NotificationVisibility.visibilityPublic,
      flag: fow.OverlayFlag.defaultFlag,
    );
    await prefs.setBool('overlay_active', true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              const Text(
                'Anteprima Icona Widget:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              _buildPreviewImage(),
              const SizedBox(height: 15),
              Text(
                'Livello attuale: $_batteryLevel%',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _remainingTime,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Card Diagnostica Batteria
              DiagnosticCard(
                health: _health,
                temp: _temp,
                voltage: _voltage,
                technology: _technology,
                isFahrenheit: _isFahrenheit,
              ),

              const SizedBox(height: 15),

              // Selettore Skin
              const Text(
                'Scegli una Skin:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: BatterySkin.values
                    .map(
                      (skin) => ChoiceChip(
                        label: Text(skin.label),
                        selected: _selectedSkin == skin,
                        onSelected: (selected) {
                          if (selected) _changeSkin(skin);
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 20),

              // Card Impostazioni Personalizzate
              SettingsCard(
                isFahrenheit: _isFahrenheit,
                enableGlow: _enableGlow,
                alertThreshold: _alertThreshold,
                refreshIntervalSeconds: _refreshIntervalSeconds,
                onFahrenheitChanged: (val) {
                  setState(() => _isFahrenheit = val);
                  _updateSetting('is_fahrenheit', val);
                },
                onGlowChanged: (val) {
                  setState(() => _enableGlow = val);
                  _updateSetting('enable_glow', val);
                },
                onAlertThresholdChanged: (val) {
                  if (val != null) {
                    setState(() => _alertThreshold = val);
                    _updateSetting('alert_threshold', val);
                  }
                },
                onRefreshIntervalChanged: (val) {
                  if (val != null) {
                    setState(() => _refreshIntervalSeconds = val);
                    _updateSetting('refresh_interval_seconds', val);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Pulsanti Azione
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _updateWidget,
                      icon: const Icon(Icons.sync),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Applica ai Widget'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleOverlay,
                      icon: const Icon(Icons.layers),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Toggle Overlay'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.teal.shade100,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
