package com.deflomick.dahlia_battery_widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.deflomick.dahlia_battery_widget.R
import java.io.File

abstract class BaseBatteryWidgetProvider(private val layoutResId: Int) : HomeWidgetProvider() {

    override fun onUpdate(
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

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(packageName, layoutResId)

            try {
                // 1. Livello Batteria
                val level = widgetData.getInt("level_v2", widgetData.getInt("battery_level", 100))
                try {
                    views.setTextViewText(R.id.battery_text, "$level%")
                } catch (_: Exception) {}

                // 2. Temperatura
                val temp = widgetData.getString("temp_v2", null)
                try {
                    if (temp != null) {
                        views.setViewVisibility(R.id.temp_text, View.VISIBLE)
                        views.setTextViewText(R.id.temp_text, temp)
                    } else {
                        views.setViewVisibility(R.id.temp_text, View.GONE)
                    }
                } catch (_: Exception) {}

                // 2.5 Voltaggio
                val voltage = widgetData.getString("voltage_v2", null)
                try {
                    if (voltage != null) {
                        views.setViewVisibility(R.id.voltage_text, View.VISIBLE)
                        views.setTextViewText(R.id.voltage_text, "$voltage V")
                    } else {
                        views.setViewVisibility(R.id.voltage_text, View.GONE)
                    }
                } catch (_: Exception) {}

                // 3. Icona e Testo Ricarica
                val isCharging = widgetData.getBoolean("charging_v2", false)
                try {
                    views.setViewVisibility(R.id.charging_icon, if (isCharging) View.VISIBLE else View.GONE)
                } catch (_: Exception) {}

                try {
                    views.setTextViewText(R.id.status_text, if (isCharging) "In carica" else "In scarica")
                } catch (_: Exception) {}

                // 4. Immagine Skin (Valutazione Dinamica Nativa del Livello)
                val selectedSkin = widgetData.getString("selected_skin", "theDahlia")
                var imageLoaded = false

                if (selectedSkin == "theDahlia" || selectedSkin == null) {
                    val drawableRes = when {
                        level < 40 -> R.drawable.ic_dahlia_low
                        level >= 80 -> R.drawable.ic_dahlia_high
                        else -> R.drawable.ic_dahlia_mid
                    }
                    try {
                        views.setImageViewResource(R.id.battery_image, drawableRes)
                        imageLoaded = true
                    } catch (_: Exception) {}
                }

                if (!imageLoaded) {
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
                }

                if (!imageLoaded) {
                    try {
                        views.setImageViewResource(
                            R.id.battery_image,
                            android.R.drawable.ic_lock_idle_low_battery
                        )
                    } catch (_: Exception) {}
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
