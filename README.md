# 🌸 The Dahlia Theme - Battery Widget & Overlay

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-5.0%2B-green.svg?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)

An elegant, highly customizable Flutter application and Android Home Widget suite featuring real-time battery diagnostics, interactive floating overlay windows, and dynamic floral skins.

---

## ✨ Features

### 🌸 Dynamic Battery Skins & Themes
- **The Dahlia Skin**: Unique floral theme that dynamically changes color based on battery level:
  - 🟢 **80% - 100%**: Vibrant Green Blooming Dahlia
  - 🟡 **40% - 79%**: Warm Golden Dahlia
  - 🔴 **0% - 39%**: Energetic Red Dahlia with subtle pulsing animation
- **Multiple Visual Styles**: Choose between *Classic*, *Neon*, *Minimal*, *The Dahlia*, and *Standard Android Icons*.
- **Glow Effect Toggle**: Enable or disable the glowing ambient aura around the battery skin.

### 📱 Multi-Size Android Home Screen Widgets
Supports **3 distinct native Android widget sizes** for any home screen layout:
1. **1x1 Compact Widget**: Minimalist single-cell tile showing skin icon and percentage.
2. **2x2 Standard Widget**: Balanced layout displaying percentage, temperature, voltage, and charging indicator.
3. **4x1 Horizontal Banner**: Extended banner showing large percentage, live status (*In Carica / In Scarica*), temperature, and voltage.

### 🖼️ Floating Overlay Window
- Draggable, floating battery widget visible over any Android app.
- Real-time synchronization with battery events and skin preferences.

### 📊 Advanced Battery Diagnostics
- **Real-Time Monitoring**: Battery Percentage, Temperature (°C / °F), Voltage (V), and Health Status (*Good, Overheat, etc.*).
- **Charge Time Estimation**: Estimated time remaining until full charge (Android 9+).
- **Smart Charge Alert**: Configurable notification/alert when battery reaches 80%, 90%, or 100% to protect battery longevity.

### ⚙️ Customizable Settings
- **Temperature Units**: Switch between Celsius (`°C`) and Fahrenheit (`°F`).
- **Background Refresh Rate**: Adjustable foreground service intervals (30 sec, 1 min, 5 min, 15 min).
- **Native Android Performance**: 100% native resource loading in Android widgets for zero background lag and smooth performance.

---

## 📸 Screenshots & Previews

| Dashboard & Settings | Home Widgets (1x1, 2x2, 4x1) | Floating Overlay |
| :---: | :---: | :---: |
| Real-time stats, skin picker, and diagnostic cards | Native Android home screen widgets in 3 formats | Draggable floating widget overlay |

---

## 🛠️ Architecture & Tech Stack

- **Frontend**: Flutter (Dart), Material 3 Design
- **Android Native**: Kotlin (`AppWidgetProvider`, `RemoteViews`, `BatteryManager`)
- **Key Plugins**:
  - `home_widget`: Android Home Screen Widget sync
  - `flutter_overlay_window`: System Alert Window floating overlay
  - `flutter_foreground_task`: Reliable Android foreground background task
  - `battery_plus`: Core battery hardware API
  - `shared_preferences`: Persistent settings & theme state

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.5.0`)
- [Android Studio](https://developer.android.com/studio) or VS Code
- Android Device / Emulator running Android 5.0 (API level 21) or higher

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

3. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── battery_widget_service.dart   # Singleton battery service & broadcast stream
└── main.dart                     # App entry point, Dashboard UI, Settings & Overlay
android/app/src/main/
├── kotlin/.../BatteryWidgetProvider.kt  # Native Android AppWidgetProvider (1x1, 2x2, 4x1)
├── res/layout/                          # Widget XML layouts (compact, standard, horizontal)
└── res/drawable/                        # Native Dahlia asset drawables
assets/images/                           # High-res Flutter Dahlia images
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Developed with ❤️ using Flutter & Kotlin.
