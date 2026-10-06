# 🌸 The Dahlia Theme - Battery Widget & Overlay

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-5.0%2B-green.svg?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)

An elegant, highly customizable Flutter application and Android Home Widget suite featuring real-time battery diagnostics, interactive floating overlay windows, and dynamic visual skins.

> [!NOTE]
> **Primary Platform Target**: While the UI is built with cross-platform Flutter, the advanced system integrations (Home Screen Widgets, System Alert Window Overlay, and Foreground Service) specifically target **Android** (API 21+).

---

## ✨ Features

### 🌸 Dynamic Battery Skins & Themes
- **The Dahlia Skin**: Unique floral theme that dynamically changes state based on battery percentage:
  - 🟢 **80% - 100%**: Vibrant Green Blooming Dahlia
  - 🟡 **40% - 79%**: Warm Golden Dahlia
  - 🔴 **0% - 39%**: Energetic Red Dahlia with subtle pulsing animation
- **Multiple Visual Styles**: Choose between *Classic*, *Neon*, *Minimal*, *The Dahlia*, and *Standard*.
- **Ambient Glow Toggle**: Enable or disable the luminous aura around the Dahlia flower.

### 📱 Multi-Size Android Home Screen Widgets
Supports **3 distinct native Android widget configurations**:
1. **1x1 Compact Widget**: Minimalist single-cell tile showing skin icon and percentage.
2. **2x2 Standard Widget**: Balanced layout displaying percentage, temperature, voltage, and charging indicator.
3. **4x1 Horizontal Banner**: Extended banner showing battery percentage, live status (*In carica / In scarica*), temperature, and voltage.

### 🖼️ Floating Overlay Window
- Draggable, floating battery indicator visible over other Android applications using `SYSTEM_ALERT_WINDOW`.
- Live synchronization with battery charging events and user skin preferences.

### 📊 Battery Diagnostics & Telemetry
- **Hardware Telemetry**: Battery Percentage, Temperature (°C / °F), Voltage (V), Health Status (*Good, Overheat, etc.*), and Battery Technology (*e.g. Li-ion*).
- **Charge Time Estimation**: Estimated time remaining until full charge (Android 9+).
- **Smart Charge Alert**: Configurable in-app notification when battery reaches 80%, 90%, or 100% to help preserve battery longevity.

### ⚙️ Customizable Settings
- **Temperature Units**: Switch between Celsius (`°C`) and Fahrenheit (`°F`).
- **Background Refresh Rate**: Adjustable foreground service interval (30 sec, 1 min, 5 min, 15 min).
- **Native Android Performance**: Native resource loading in AppWidgetProvider for fast rendering and battery efficiency.

---

## 📸 Screenshots & Previews

<!-- Placeholders for project portfolio screenshots -->

| Dashboard & Settings | Home Widgets (1x1, 2x2, 4x1) | Floating Overlay |
| :---: | :---: | :---: |
| *Add screenshot: `docs/screenshots/dashboard.png`* <br> *(Real-time stats, skin selector & diagnostic cards)* | *Add screenshot: `docs/screenshots/widgets.png`* <br> *(Android home screen widgets in 3 formats)* | *Add screenshot: `docs/screenshots/overlay.png`* <br> *(Draggable floating widget overlay on home screen)* |

---

## 🏗️ Architecture

The app uses a modular reactive pipeline bridging Flutter's UI with Android native APIs and background services:

```text
Flutter UI (Dashboard & Settings)
       ↓
BatteryWidgetService (Singleton Stream & Telemetry Provider)
       ↓
battery_plus  &  MethodChannel ("com.example.mdfy_theme/battery")
       ↓
HomeWidget (SharedPreferences Sync)  &  FlutterForegroundTask
       ↓
Android AppWidgetProvider (1x1, 2x2, 4x1 RemoteViews) & Overlay Isolate
```

---

## 🛠️ Tech Stack & Plugins

- **Framework**: Flutter (Dart 3.5+), Material 3
- **Native Android**: Kotlin (`AppWidgetProvider`, `RemoteViews`, `BatteryManager`, `MethodChannel`)
- **Key Plugins**:
  - `home_widget`: Android Home Screen Widget persistence & update broadcast
  - `flutter_overlay_window`: Floating overlay window management
  - `flutter_foreground_task`: Reliable Android background task execution
  - `battery_plus`: Core battery state & level polling
  - `shared_preferences`: Persistent settings & preference storage

---

## 📁 Project Structure

```text
lib/
├── enums/
│   └── battery_skin.dart           # Battery visual skins & asset threshold resolver
├── models/
│   └── battery_data.dart           # Immutable typed battery snapshot model
├── overlay/
│   └── battery_overlay.dart        # Floating overlay UI & VM isolate entry point
├── painters/
│   └── battery_skin_painter.dart   # Vector skin painter with optimized repaint checks
├── screens/
│   └── home_screen.dart            # Main dashboard, telemetry view & action buttons
├── services/
│   ├── battery_widget_service.dart # Battery monitoring, formatting & HomeWidget sync
│   └── foreground_service.dart     # Android background task handler & lifecycle
├── widgets/
│   ├── battery_image_widget.dart   # Visual preview & HomeWidget render widget
│   ├── diagnostic_card.dart        # Live telemetry information card
│   └── settings_card.dart          # User preferences & threshold controls
└── main.dart                       # App entry point, theme & isolate VM hooks

android/app/src/main/
├── kotlin/.../
│   ├── BatteryWidgetProvider.kt    # Base & specialized AppWidgetProviders (1x1, 2x2, 4x1)
│   └── MainActivity.kt             # MethodChannel handling BatteryManager telemetry
├── res/layout/                     # Native XML widget layouts
└── res/drawable/                   # Native Dahlia assets for zero-lag widget rendering
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.5.0`)
- [Android Studio](https://developer.android.com/studio) or VS Code
- Android physical device or emulator with API Level 21 (Android 5.0 Lollipop) or higher

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Deflomick/dahlia_battery_widget.git
   cd dahlia_battery_widget
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Static Analysis & Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch on Android**:
   ```bash
   flutter run
   ```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
