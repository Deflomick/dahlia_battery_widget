package com.deflomick.dahlia_battery_widget

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        const val CHANNEL = "com.deflomick.dahlia_battery_widget/battery"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryExtraInfo") {
                try {
                    val batteryInfo = getBatteryExtraInfo()
                    result.success(batteryInfo)
                } catch (_: Throwable) {
                    result.success(emptyMap<String, Any?>())
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getBatteryExtraInfo(): Map<String, Any?> {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = registerReceiver(null, intentFilter)

        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        
        // Temperatura in decimi di grado Celsius (es: 355 = 35.5°C)
        val temperature = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        
        // Tempo rimanente alla ricarica completa (disponibile da Android 9+)
        var chargeTimeRemaining: Long = -1
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                chargeTimeRemaining = bm.computeChargeTimeRemaining()
            } catch (_: Throwable) {
                chargeTimeRemaining = -1
            }
        }

        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0 // in mV
        val healthCode = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) ?: BatteryManager.BATTERY_HEALTH_UNKNOWN
        val healthString = when (healthCode) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Buona"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Surriscaldata"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Scaricata"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Sovratensione"
            BatteryManager.BATTERY_HEALTH_COLD -> "Fredda"
            else -> "Sconosciuta"
        }

        return mapOf(
            "temperature" to temperature / 10.0,
            "chargeTimeRemaining" to chargeTimeRemaining, // in millisecondi
            "voltage" to voltage / 1000.0, // in Volt
            "health" to healthString,
            "technology" to batteryStatus?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)
        )
    }
}
