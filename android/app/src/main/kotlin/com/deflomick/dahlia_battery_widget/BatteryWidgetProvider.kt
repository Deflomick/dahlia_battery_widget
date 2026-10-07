package com.deflomick.dahlia_battery_widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.BatteryManager
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import com.deflomick.dahlia_battery_widget.R
import java.io.File
import java.util.Locale

abstract class BaseBatteryWidgetProvider(private val layoutResId: Int) : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_POWER_CONNECTED ||
            action == Intent.ACTION_POWER_DISCONNECTED ||
            action == Intent.ACTION_BATTERY_LOW ||
            action == Intent.ACTION_BATTERY_OKAY ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_USER_PRESENT
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, javaClass)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val widgetData = HomeWidgetPlugin.getData(context)
                updateWidgets(context, appWidgetManager, appWidgetIds, widgetData)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds, widgetData)
    }

    private fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val packageName = context.packageName
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else null

        // 0. Query Live Hardware Battery State from Android system
        val batteryStatus: Intent? = try {
            context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        } catch (_: Exception) {
            null
        }

        val rawLevel = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val nativeLevel = if (rawLevel >= 0 && scale > 0) (rawLevel * 100) / scale else -1

        val level = if (nativeLevel in 0..100) {
            nativeLevel
        } else {
            widgetData.getInt("level_v2", widgetData.getInt("battery_level", 100))
        }

        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = if (status != -1) {
            status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        } else {
            widgetData.getBoolean("charging_v2", false)
        }

        // Keep SharedPreferences aligned with the real battery state
        try {
            widgetData.edit()
                .putInt("level_v2", level)
                .putBoolean("charging_v2", isCharging)
                .apply()
        } catch (_: Exception) {}

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(packageName, layoutResId)

            try {
                // 1. Livello Batteria
                views.setTextViewText(R.id.battery_text, "$level%")

                // 2. Temperatura
                val rawTemp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
                val temp = if (rawTemp > 0) {
                    val tempC = rawTemp / 10.0
                    val isFahrenheit = widgetData.getBoolean("is_fahrenheit", false)
                    if (isFahrenheit) {
                        val tempF = (tempC * 9.0 / 5.0) + 32.0
                        String.format(Locale.US, "%.1f°F", tempF)
                    } else {
                        String.format(Locale.US, "%.1f°C", tempC)
                    }
                } else {
                    widgetData.getString("temp_v2", null)
                }
                try {
                    if (temp != null) {
                        views.setViewVisibility(R.id.temp_text, View.VISIBLE)
                        views.setTextViewText(R.id.temp_text, temp)
                    } else {
                        views.setViewVisibility(R.id.temp_text, View.GONE)
                    }
                } catch (_: Exception) {}

                // 2.5 Voltaggio (con normalizzazione robusta dell'unità "V")
                val rawVolt = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
                val voltage = if (rawVolt > 0) {
                    String.format(Locale.US, "%.2f V", rawVolt / 1000.0)
                } else {
                    val savedVolt = widgetData.getString("voltage_v2", null)?.trim()
                    if (savedVolt != null && savedVolt.isNotEmpty()) {
                        if (savedVolt.endsWith("V", ignoreCase = true)) savedVolt else "$savedVolt V"
                    } else null
                }
                try {
                    if (voltage != null) {
                        views.setViewVisibility(R.id.voltage_text, View.VISIBLE)
                        views.setTextViewText(R.id.voltage_text, voltage)
                    } else {
                        views.setViewVisibility(R.id.voltage_text, View.GONE)
                    }
                } catch (_: Exception) {}

                // 3. Icona e Testo Ricarica
                try {
                    views.setViewVisibility(R.id.charging_icon, if (isCharging) View.VISIBLE else View.GONE)
                } catch (_: Exception) {}

                try {
                    views.setTextViewText(R.id.status_text, if (isCharging) "In carica" else "In scarica")
                } catch (_: Exception) {}

                // 4. Immagine Skin
                val selectedSkin = widgetData.getString("selected_skin", "theDahlia")

                if (selectedSkin == "theDahlia" || selectedSkin == null) {
                    // Per la skin The Dahlia il drawable nativo viene scelto SEMPRE
                    // dinamicamente in base al livello attuale di carica:
                    //   < 40%    -> ic_dahlia_low
                    //   40-79%   -> ic_dahlia_mid
                    //   >= 80%   -> ic_dahlia_high
                    val drawableRes = when {
                        level < 40  -> R.drawable.ic_dahlia_low
                        level >= 80 -> R.drawable.ic_dahlia_high
                        else        -> R.drawable.ic_dahlia_mid
                    }
                    try {
                        views.setImageViewResource(R.id.battery_image, drawableRes)
                    } catch (_: Exception) {}
                } else {
                    // Per le altre skin (Neon, Classic, Minimal, ecc.) usa la bitmap
                    // renderizzata da Flutter salvata in SharedPreferences, con fallback sicuro
                    var imageLoaded = false
                    val imagePath = widgetData.getString("battery_image", null)
                    if (imagePath != null) {
                        val bitmap = loadBitmapSafely(imagePath)
                        if (bitmap != null) {
                            try {
                                views.setImageViewBitmap(R.id.battery_image, bitmap)
                                imageLoaded = true
                            } catch (_: Exception) {}
                        }
                    }

                    if (!imageLoaded) {
                        try {
                            views.setImageViewResource(
                                R.id.battery_image,
                                android.R.drawable.ic_lock_idle_low_battery
                            )
                        } catch (_: Exception) {}
                    }
                }

                // 5. Impostazione PendingIntent
                if (pendingIntent != null) {
                    try {
                        views.setOnClickPendingIntent(R.id.battery_image, pendingIntent)
                        views.setOnClickPendingIntent(R.id.battery_text, pendingIntent)
                    } catch (_: Exception) {}
                }

            } catch (e: Exception) {
                Log.e("BatteryWidget", "Errore durante l'aggiornamento del widget $appWidgetId", e)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun loadBitmapSafely(path: String): Bitmap? {
        return try {
            val file = File(path)
            if (file.exists()) {
                BitmapFactory.decodeFile(file.absolutePath)
            } else null
        } catch (e: Exception) {
            Log.w("BatteryWidget", "Impossibile decodificare la bitmap: $path", e)
            null
        }
    }
}

class BatteryWidgetProvider : BaseBatteryWidgetProvider(R.layout.battery_widget)
class BatteryWidgetCompactProvider : BaseBatteryWidgetProvider(R.layout.battery_widget_compact)
class BatteryWidgetHorizontalProvider : BaseBatteryWidgetProvider(R.layout.battery_widget_horizontal)
