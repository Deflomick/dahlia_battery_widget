import 'package:flutter/material.dart';
import 'overlay/battery_overlay.dart' as overlay;
import 'screens/home_screen.dart';
import 'services/foreground_service.dart' as foreground;

/// Punto di ingresso principale dell'applicazione "The Dahlia Theme".
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DahliaBatteryApp());
}

/// Punto di ingresso VM per il processo isolato del Foreground Task.
@pragma('vm:entry-point')
void startCallback() {
  foreground.startCallback();
}

/// Punto di ingresso VM per l'Isolate dell'Overlay di sistema.
@pragma('vm:entry-point')
void overlayMain() {
  overlay.overlayMain();
}

/// Widget radice che configura il tema Material 3 e la schermata iniziale.
class DahliaBatteryApp extends StatelessWidget {
  const DahliaBatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Dahlia Theme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(title: 'The Dahlia Theme'),
    );
  }
}
