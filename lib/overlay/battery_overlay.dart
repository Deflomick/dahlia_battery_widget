import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as fow;
import 'package:shared_preferences/shared_preferences.dart';
import '../enums/battery_skin.dart';
import '../models/battery_data.dart';
import '../painters/battery_skin_painter.dart';
import '../services/battery_widget_service.dart';

/// Punto di ingresso isolato dedicato all'Overlay di sistema.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BatteryOverlay(),
  ));
}

/// Widget che rappresenta l'interfaccia dell'overlay fluttuante.
class BatteryOverlay extends StatefulWidget {
  const BatteryOverlay({super.key});

  @override
  State<BatteryOverlay> createState() => _BatteryOverlayState();
}

class _BatteryOverlayState extends State<BatteryOverlay>
    with TickerProviderStateMixin {
  int _level = 0;
  bool _isCharging = false;
  String _remainingTime = "--";
  BatterySkin _selectedSkin = BatterySkin.theDahlia;
  bool _enableGlow = true;

  late AnimationController _pulseController;
  ReceivePort? _receivePort;
  StreamSubscription<BatteryData>? _batterySubscription;
  StreamSubscription<dynamic>? _overlayListenerSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _initBattery();
    _listenForData();
    _initForegroundPort();
  }

  void _initForegroundPort() {
    _receivePort = FlutterForegroundTask.receivePort;
    _receivePort?.listen((message) {
      if (message is Map && mounted) {
        setState(() {
          if (message.containsKey('level')) {
            _level = message['level'] as int? ?? _level;
          }
          if (message.containsKey('isCharging')) {
            _isCharging = message['isCharging'] as bool? ?? _isCharging;
          }
        });
      }
    });
  }

  void _listenForData() {
    _overlayListenerSubscription =
        fow.FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && mounted) {
        setState(() {
          if (data.containsKey('skin')) {
            try {
              _selectedSkin = BatterySkin.values.byName(data['skin']);
            } catch (e) {
              debugPrint("Errore parsing skin ricevuto in overlay: $e");
            }
          }
          if (data.containsKey('enableGlow')) {
            _enableGlow = data['enableGlow'] as bool? ?? true;
          }
        });
      }
    });
  }

  Future<void> _initBattery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSkin = prefs.getString(BatteryWidgetService.keySelectedSkin);
      _enableGlow = prefs.getBool('enable_glow') ?? true;
      if (savedSkin != null) {
        setState(() {
          try {
            _selectedSkin = BatterySkin.values.byName(savedSkin);
          } catch (_) {
            _selectedSkin = BatterySkin.theDahlia;
          }
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento skin overlay: $e");
    }

    final service = BatteryWidgetService();
    service.startMonitoring();
    _batterySubscription = service.batteryStream.listen((data) {
      if (mounted) {
        if ((_level - data.level).abs() > 5) {
          PaintingBinding.instance.imageCache.clear();
        }

        setState(() {
          _level = data.level;
          _isCharging = data.isCharging;

          if (_isCharging) {
            final int chargeTime = data.chargeTimeRemaining;
            _remainingTime = service.formatTime(chargeTime);
          } else {
            _remainingTime = "--";
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _receivePort?.close();
    _batterySubscription?.cancel();
    _overlayListenerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_selectedSkin == BatterySkin.theDahlia && _enableGlow)
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _level >= 80
                            ? Colors.greenAccent.withOpacity(0.5)
                            : (_level >= 40
                                ? Colors.yellowAccent.withOpacity(0.4)
                                : Colors.redAccent.withOpacity(0.5)),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              if (_selectedSkin == BatterySkin.theDahlia)
                ScaleTransition(
                  scale: _level > 0 && _level < 40
                      ? Tween<double>(begin: 1.0, end: 1.2).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        )
                      : const AlwaysStoppedAnimation(1.0),
                  child: Image.asset(
                    getDahliaAssetPath(_level),
                    width: 80,
                    height: 80,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.battery_alert,
                        color: Colors.white,
                        size: 50),
                  ),
                ),
              if (_selectedSkin != BatterySkin.standardAsset &&
                  _selectedSkin != BatterySkin.theDahlia)
                CustomPaint(
                  size: const Size(80, 80),
                  painter: BatterySkinPainter(
                    skin: _selectedSkin,
                    level: _level,
                  ),
                ),
              if (_selectedSkin == BatterySkin.standardAsset)
                const Icon(Icons.battery_std, color: Colors.white, size: 50),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_level%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 6,
                          ),
                          const Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    if (_isCharging && _remainingTime != "--")
                      Text(
                        _remainingTime,
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
