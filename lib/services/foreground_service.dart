import 'dart:isolate';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:home_widget/home_widget.dart';
import 'battery_widget_service.dart';

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
      await HomeWidget.saveWidgetData<int>(
          BatteryWidgetService.keyLevel, level);
      await HomeWidget.saveWidgetData<bool>(
        BatteryWidgetService.keyCharging,
        isCharging,
      );

      for (final widgetName in BatteryWidgetService.androidWidgetNames) {
        await HomeWidget.updateWidget(androidName: widgetName);
      }
    } catch (e) {
      debugPrint("Errore aggiornamento widget nel task foreground: $e");
    }

    sendPort?.send({
      'level': level,
      'isCharging': isCharging,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}

/// Inizializza e avvia il servizio in primo piano [FlutterForegroundTask].
Future<void> startForegroundService({int intervalMs = 60000}) async {
  // Su Android 13+ richiede il permesso POST_NOTIFICATIONS se non ancora accordato
  final NotificationPermission permission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (permission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'dahlia_battery_service_channel',
      channelName: 'Dahlia Battery Monitor',
      channelDescription: 'Monitoraggio batteria e aggiornamenti widget Dahlia',
      channelImportance: NotificationChannelImportance.DEFAULT,
      priority: NotificationPriority.DEFAULT,
      enableVibration: false,
      playSound: false,
      showWhen: false,
      iconData: const NotificationIconData(
        resType: ResourceType.drawable,
        resPrefix: ResourcePrefix.ic,
        name: 'dahlia_notification',
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
    notificationTitle: 'Dahlia Battery Monitor',
    notificationText: 'Monitoraggio batteria attivo',
    callback: startCallback,
  );
}

/// Arresta il servizio [FlutterForegroundTask].
Future<void> stopForegroundService() async {
  await FlutterForegroundTask.stopService();
}
