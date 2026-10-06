/// Il punto di ingresso principale dell'applicazione "The Dahlia Theme".
///
/// Questo file si occupa dell'inizializzazione dell'app, della configurazione
/// del servizio in primo piano (foreground task) per il monitoraggio continuo
/// e della gestione dell'interfaccia utente principale (Dashboard, Impostazioni e Overlay).
import 'dart:isolate';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as fow;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'battery_widget_service.dart';

/// Definisce gli stili visuali disponibili per l'icona della batteria.
enum BatterySkin { 
  /// Stile rettangolare classico con polo positivo.
  classic, 
  /// Cerchio luminoso con effetto neon.
  neon, 
  /// Semplice arco di cerchio che rappresenta la percentuale.
  minimal, 
  /// Tema floreale personalizzato con petali dinamici.
  theDahlia, 
  /// Utilizza le icone standard del sistema Android.
  standardAsset 
}

/// Inizializza i componenti fondamentali e avvia l'applicazione.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Punto di ingresso obbligatorio per il processo isolato del Foreground Task.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

/// Gestore degli eventi per il task eseguito in background/foreground.
class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final battery = Battery();
    final int level = await battery.batteryLevel;
    final state = await battery.batteryState;
    final isCharging = state == BatteryState.charging;

    try {
      await HomeWidget.saveWidgetData<int>(BatteryWidgetService.keyLevel, level);
      await HomeWidget.saveWidgetData<bool>(BatteryWidgetService.keyCharging, isCharging);
      
      await HomeWidget.updateWidget(androidName: 'BatteryWidgetProvider');
      await HomeWidget.updateWidget(androidName: 'BatteryWidgetCompactProvider');
      await HomeWidget.updateWidget(androidName: 'BatteryWidgetHorizontalProvider');
    } catch (e) {
      // Errori ignorati nel contesto di background
    }
    
    sendPort?.send({
      'level': level,
      'isCharging': isCharging,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}

/// Configura e avvia il servizio [FlutterForegroundTask].
Future<void> _startForegroundService({int intervalMs = 60000}) async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'battery_status_channel',
      channelName: 'Stato Batteria Dahlia',
      channelDescription: 'Mantiene l\'overlay della batteria attivo in background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      interval: intervalMs,
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  await FlutterForegroundTask.startService(
    notificationTitle: 'Batteria Dahlia Attiva',
    notificationText: 'L\'overlay personalizzato è in esecuzione',
    callback: startCallback,
  );
}

/// Widget che rappresenta l'interfaccia dell'overlay fluttuante.
class BatteryOverlay extends StatefulWidget {
  const BatteryOverlay({super.key});

  @override
  State<BatteryOverlay> createState() => _BatteryOverlayState();
}

class _BatteryOverlayState extends State<BatteryOverlay> with TickerProviderStateMixin {
  int _level = 0;
  bool _isCharging = false;
  String _remainingTime = "--";
  BatterySkin _selectedSkin = BatterySkin.theDahlia;
  bool _enableGlow = true;
  
  late AnimationController _pulseController;
  ReceivePort? _receivePort;

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

  void _initForegroundPort() async {
    _receivePort = FlutterForegroundTask.receivePort;
    _receivePort?.listen((message) {
      if (message is Map && mounted) {
        setState(() {
          if (message.containsKey('level')) _level = message['level'];
          if (message.containsKey('isCharging')) _isCharging = message['isCharging'];
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _receivePort?.close();
    super.dispose();
  }

  void _listenForData() {
    fow.FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          if (data.containsKey('skin')) {
            _selectedSkin = BatterySkin.values.byName(data['skin']);
          }
          if (data.containsKey('enableGlow')) {
            _enableGlow = data['enableGlow'];
          }
        });
      }
    });
  }

  void _initBattery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSkin = prefs.getString('selected_skin');
      _enableGlow = prefs.getBool('enable_glow') ?? true;
      if (savedSkin != null) {
        setState(() {
          _selectedSkin = BatterySkin.values.byName(savedSkin);
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento skin overlay: $e");
    }

    BatteryWidgetService().startMonitoring();
    BatteryWidgetService().batteryStream.listen((data) {
      if (mounted) {
        if ((_level - data.level).abs() > 5) {
          PaintingBinding.instance.imageCache.clear();
        }
        
        setState(() {
          _level = data.level;
          _isCharging = data.isCharging;
          
          if (_isCharging) {
            final int chargeTime = data.extra['chargeTimeRemaining'] ?? -1;
            _remainingTime = BatteryWidgetService().formatTime(chargeTime);
          } else {
            _remainingTime = "--";
          }
        });
      }
    });
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
                            : (_level >= 40 ? Colors.yellowAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.5)),
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
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        )
                      : const AlwaysStoppedAnimation(1.0),
                  child: Image.asset(
                    _level < 40 
                        ? 'assets/images/dahlia_low.png' 
                        : (_level >= 80 
                            ? 'assets/images/dahlia_high.png' 
                            : 'assets/images/dahlia_mid.png'),
                    width: 80,
                    height: 80,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.battery_alert, color: Colors.white, size: 50),
                  ),
                ),

              if (_selectedSkin != BatterySkin.standardAsset && _selectedSkin != BatterySkin.theDahlia)
                CustomPaint(
                  size: const Size(80, 80),
                  painter: BatterySkinPainter(skin: _selectedSkin, level: _level),
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
                          Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 6),
                          const Shadow(color: Colors.black, offset: Offset(1, 1)),
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
                          shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4)],
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

/// Punto di ingresso dell'Isolate dedicato all'Overlay.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BatteryOverlay(),
  ));
}

/// Painter per il disegno delle skin vettoriali della batteria.
class BatterySkinPainter extends CustomPainter {
  final BatterySkin skin;
  final int level;

  BatterySkinPainter({required this.skin, required this.level});

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
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
      canvas.drawRect(Rect.fromLTWH(size.width - 20, 35, 5, 10), paint);
    } else if (skin == BatterySkin.minimal) {
      final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
      canvas.drawArc(rect, -1.57, (level / 100) * 6.28, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget principale dell'app che definisce il tema e la home page.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Dahlia Theme',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'The Dahlia Theme'),
    );
  }
}

/// Dashboard principale dell'utente.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _batteryLevel = 0;
  bool _isCharging = false;
  String _remainingTime = "--";
  double _temp = 0.0;
  double _voltage = 0.0;
  String _health = "Buona";
  String _technology = "Li-ion";
  
  // Settaggi personalizzati
  bool _isFahrenheit = false;
  bool _enableGlow = true;
  int _alertThreshold = 80; // 0 = Disattivato, 80, 90, 100
  int _refreshIntervalSeconds = 60; // 30, 60, 300, 900
  
  BatterySkin _selectedSkin = BatterySkin.neon;
  final BatteryWidgetService _batteryService = BatteryWidgetService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initBattery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverlayOnBoot();
    });
  }

  Future<void> _checkOverlayOnBoot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isOverlayActive = prefs.getBool('overlay_active') ?? false;
      final int refreshInterval = prefs.getInt('refresh_interval_seconds') ?? 60;
      
      if (isOverlayActive) {
        await _startForegroundService(intervalMs: refreshInterval * 1000);
      }
    } catch (e) {
      debugPrint("Errore ripristino service all'avvio: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFahrenheit = prefs.getBool('is_fahrenheit') ?? false;
      _enableGlow = prefs.getBool('enable_glow') ?? true;
      _alertThreshold = prefs.getInt('alert_threshold') ?? 80;
      _refreshIntervalSeconds = prefs.getInt('refresh_interval_seconds') ?? 60;
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    
    _updateWidget(silent: true);
    
    if (key == 'enable_glow' && await fow.FlutterOverlayWindow.isActive()) {
      await fow.FlutterOverlayWindow.shareData({'enableGlow': value});
    }
  }

  Future<void> _changeSkin(BatterySkin skin) async {
    setState(() => _selectedSkin = skin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_skin', skin.name);
    await HomeWidget.saveWidgetData<String>('selected_skin', skin.name);
    
    if (await fow.FlutterOverlayWindow.isActive()) {
      await fow.FlutterOverlayWindow.shareData({'skin': skin.name});
    }
    _updateWidget(silent: true);
  }

  void _initBattery() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSkin = prefs.getString('selected_skin');
    if (savedSkin != null) {
      _selectedSkin = BatterySkin.values.byName(savedSkin);
      await HomeWidget.saveWidgetData<String>('selected_skin', _selectedSkin.name);
    }

    _batteryService.startMonitoring();
    _batteryService.batteryStream.listen((data) {
      if (!mounted) return;
      
      bool wasCharging = _isCharging;
      int oldLevel = _batteryLevel;

      setState(() {
        _batteryLevel = data.level;
        _isCharging = data.isCharging;
        _temp = data.extra['temperature'] ?? 0.0;
        _voltage = data.extra['voltage'] ?? 0.0;
        _health = data.extra['health'] ?? "Buona";
        _technology = data.extra['technology'] ?? "Li-ion";
        
        if (_isCharging) {
          final int chargeTime = data.extra['chargeTimeRemaining'] ?? -1;
          _remainingTime = "Fine tra ${_batteryService.formatTime(chargeTime)}";
        } else {
          _remainingTime = "Scarica stimata: --";
        }
      });

      // Controlla allarme carica completata
      if (_isCharging && _alertThreshold > 0 && data.level >= _alertThreshold && oldLevel < _alertThreshold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Batteria al $_batteryLevel%! Puoi staccare il caricabatterie.'),
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

  Widget _buildBatteryImage() {
    if (_selectedSkin == BatterySkin.theDahlia) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_enableGlow)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _batteryLevel >= 80 
                          ? Colors.greenAccent.withOpacity(0.4) 
                          : (_batteryLevel >= 40 ? Colors.yellowAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.4)),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            Center(
              child: Image.asset(
                _batteryLevel < 40 
                    ? 'assets/images/dahlia_low.png' 
                    : (_batteryLevel >= 80 
                        ? 'assets/images/dahlia_high.png' 
                        : 'assets/images/dahlia_mid.png'),
                width: 160,
                height: 160,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: BatterySkinPainter(skin: _selectedSkin, level: _batteryLevel),
        child: const Center(
          child: Icon(Icons.bolt, color: Colors.white54, size: 60),
        ),
      ),
    );
  }

  Future<void> _updateWidget({bool silent = false}) async {
    await _batteryService.updateBatteryWidget(
      customImageWidget: _buildBatteryImage(),
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
      await FlutterForegroundTask.stopService();
      await prefs.setBool('overlay_active', false);
      setState(() {});
      return;
    }

    final bool status = await fow.FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await fow.FlutterOverlayWindow.requestPermission();
      return;
    }

    await _startForegroundService(intervalMs: _refreshIntervalSeconds * 1000);

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double displayTemp = _isFahrenheit ? (_temp * 9 / 5) + 32 : _temp;
    final String tempUnit = _isFahrenheit ? "°F" : "°C";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            const Text('Anteprima Icona Widget:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildBatteryImage(),
            const SizedBox(height: 15),
            Text(
              'Livello attuale: $_batteryLevel%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _remainingTime,
              style: const TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Card Diagnostica Batteria
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.health_and_safety, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Diagnostica Batteria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _diagnosticItem("Salute", _health, Icons.favorite, Colors.green),
                        _diagnosticItem("Temperatura", "${displayTemp.toStringAsFixed(1)}$tempUnit", Icons.thermostat, _temp > 38 ? Colors.red : Colors.orange),
                        _diagnosticItem("Voltaggio", "${_voltage.toStringAsFixed(2)} V", Icons.electric_bolt, Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Selettore Skin
            const Text('Scegli una Skin:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                _skinButton(BatterySkin.classic, "Classic"),
                _skinButton(BatterySkin.neon, "Neon"),
                _skinButton(BatterySkin.minimal, "Minimal"),
                _skinButton(BatterySkin.theDahlia, "The Dahlia"),
                _skinButton(BatterySkin.standardAsset, "Standard"),
              ],
            ),

            const SizedBox(height: 20),

            // Card Settaggi Personalizzati
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.settings, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Impostazioni Personalizzate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    
                    // Unità Temperatura
                    SwitchListTile(
                      title: const Text('Unità Temperatura in Fahrenheit'),
                      subtitle: Text(_isFahrenheit ? 'Visualizzato in °F' : 'Visualizzato in °C'),
                      secondary: const Icon(Icons.thermostat_auto),
                      value: _isFahrenheit,
                      onChanged: (val) {
                        setState(() => _isFahrenheit = val);
                        _updateSetting('is_fahrenheit', val);
                      },
                    ),

                    // Effetto Glow
                    SwitchListTile(
                      title: const Text('Effetto Glow (Alone Luminoso)'),
                      subtitle: const Text('Mostra alone di luce attorno alla Dahlia'),
                      secondary: const Icon(Icons.light_mode),
                      value: _enableGlow,
                      onChanged: (val) {
                        setState(() => _enableGlow = val);
                        _updateSetting('enable_glow', val);
                      },
                    ),

                    // Avviso Carica
                    ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Notifica Carica Completata'),
                      subtitle: Text(_alertThreshold == 0 ? 'Disattivata' : 'Avvisa quando raggiunge il $_alertThreshold%'),
                      trailing: DropdownButton<int>(
                        value: _alertThreshold,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Disattivato')),
                          DropdownMenuItem(value: 80, child: Text('80%')),
                          DropdownMenuItem(value: 90, child: Text('90%')),
                          DropdownMenuItem(value: 100, child: Text('100%')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _alertThreshold = val);
                            _updateSetting('alert_threshold', val);
                          }
                        },
                      ),
                    ),

                    // Frequenza Aggiornamento Background
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Frequenza Aggiornamento Service'),
                      subtitle: Text('Controlla ogni $_refreshIntervalSeconds secondi'),
                      trailing: DropdownButton<int>(
                        value: _refreshIntervalSeconds,
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 sec')),
                          DropdownMenuItem(value: 60, child: Text('1 min')),
                          DropdownMenuItem(value: 300, child: Text('5 min')),
                          DropdownMenuItem(value: 900, child: Text('15 min')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _refreshIntervalSeconds = val);
                            _updateSetting('refresh_interval_seconds', val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pulsanti Azione
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _updateWidget,
                    icon: const Icon(Icons.sync),
                    label: const Text('Applica ai Widget'),
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
                    label: const Text('Toggle Overlay'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal.shade100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _diagnosticItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _skinButton(BatterySkin skin, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedSkin == skin,
      onSelected: (selected) {
        if (selected) _changeSkin(skin);
      },
    );
  }
}
