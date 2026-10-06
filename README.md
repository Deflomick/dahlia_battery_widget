# 🌸 Dahlia Battery Widget

> *An unofficial Honkai: Star Rail fan project built with Flutter and native Android integration.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-5.0%2B-green.svg?logo=android)](https://developer.android.com)
[![Kotlin](https://img.shields.io/badge/Kotlin-Android%20Native-purple.svg?logo=kotlin)](https://kotlinlang.org)
[![HSR Fan Project](https://img.shields.io/badge/Honkai%3A%20Star%20Rail-Fan%20Project-E46F7A.svg)](#-part-of-my-honkai-star-rail-fan-projects)
[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)

**Dahlia Battery Widget** is an unofficial fan project inspired by **The Dahlia / Constance** from the universe of *Honkai: Star Rail*.

The project started as a small personal experiment combining an interest in the character with mobile software development and Android native APIs. It provides a customizable battery monitor, multi-size Android home screen widgets, and a system-wide floating overlay, serving as a practical exploration of Flutter ↔ Android platform integration.

> [!NOTE]
> **Primary Platform Target**: The application's UI is built with cross-platform Flutter, while the low-level system integrations (Home Screen Widgets, Foreground Service, and System Alert Window Overlay) specifically target **Android** (API Level 21+).

---

## 🌸 Why Dahlia?

Sometimes the most rewarding side projects begin with something you simply enjoy.

Dahlia Battery Widget began as a personal experiment: turning an appreciation for The Dahlia / Constance into an interactive daily utility while diving deeper into Android platform channels, background foreground execution, and custom isolate overlays. Rather than a generic battery monitor, it was designed with an aesthetic identity inspired by the character's visual motifs.

---

## 🌌 Part of my Honkai: Star Rail Fan Projects

This widget is designed as a companion to my broader personal project: the **Honkai: Star Rail Lore Archive**, where I collect, categorize, and explore lore details about characters, factions, and universe timelines.

```text
Honkai: Star Rail Lore Archive
│
├── Lore
│   ├── Characters (including The Dahlia / Constance)
│   ├── Factions (e.g. Ever-Flame Mansion / Annihilation Gang)
│   ├── Events
│   └── Timeline
│
└── Fan Projects
    │
    └── Dahlia Battery Widget (Android companion)
        ├── Flutter & Dart UI
        ├── Native Kotlin Integration
        ├── Android Home Screen Widgets (1x1, 2x2, 4x1)
        ├── Floating Isolate Overlay
        └── Battery Telemetry APIs
```

> 🔗 **Lore Archive**: *Link coming soon*  
> <!-- Replace with your live URL when deployed: [Honkai: Star Rail Lore Archive](https://your-lore-archive-url.com) -->

---

## 📸 Screenshots & Previews

<!-- Real screenshots will be placed in the docs/screenshots/ directory -->

| 1. App Dashboard & Diagnostics | 2. Dahlia Dynamic Skin | 3. Android Home Widgets | 4. Floating Overlay Window |
| :---: | :---: | :---: | :---: |
| *Add screenshot:*<br>`docs/screenshots/dashboard.png`<br>*(Telemetry cards, health stats & settings)* | *Add screenshot:*<br>`docs/screenshots/dahlia-skin.png`<br>*(Dynamic floral level states with aura glow)* | *Add screenshot:*<br>`docs/screenshots/home-widget.png`<br>*(1x1 compact, 2x2 standard, 4x1 banner)* | *Add screenshot:*<br>`docs/screenshots/floating-overlay.png`<br>*(Draggable floating widget above system apps)* |

> [!TIP]
> **Directory Setup**: Store your real captures under `docs/screenshots/` using the file names referenced above.

---

## 🛠️ Architecture & Technical Highlights

While created as a passion project, the application demonstrates concrete software engineering patterns bridging Flutter's reactive UI with Android's platform subsystem:

```text
Flutter UI (Dashboard & Settings)
     │
     ▼
BatteryWidgetService (Singleton Stream & Telemetry Provider)
     │
     ├── battery_plus (Hardware events)
     │
     └── MethodChannel ("com.deflomick.dahlia_battery_widget/battery")
              │
              ▼
        Android / Kotlin
              │
              ├── BatteryManager (Voltage, Temperature, Charge time remaining)
              └── AppWidgetProvider (1x1, 2x2, 4x1 RemoteViews)
                       │
                       ▼
                Android Home Widget
```

### Key Technical Aspects Demonstrated:
- **Platform Interoperability**: Bi-directional communication between Dart and Kotlin via `MethodChannel` to retrieve detailed battery hardware metrics (`BatteryManager.EXTRA_TEMPERATURE`, `EXTRA_VOLTAGE`, `computeChargeTimeRemaining`).
- **Android Home Widgets**: Native Android `AppWidgetProvider` implementations (`1x1 Compact`, `2x2 Standard`, `4x1 Horizontal Banner`) using `RemoteViews` and instant data syncing via `HomeWidget`.
- **Background Execution**: Reliable background monitoring through `FlutterForegroundTask` without battery-draining polling loops.
- **Floating Overlay Window**: System Alert Window overlay running on a secondary Flutter VM entry point (`@pragma('vm:entry-point') void overlayMain()`) with touch passthrough and draggable positioning.
- **Custom Canvas Rendering**: Optimized `CustomPainter` with fine-grained `shouldRepaint` dirty checks for vector battery skins.
- **State & Resource Hygiene**: Stream broadcast architecture with complete `StreamSubscription` cleanup and timer lifecycle management.

---

## ✨ Features

- **Dynamic Dahlia Floral Skins**: Visual state transitions based on battery thresholds:
  - 🟢 **80% - 100%**: Vibrant Green Blooming Dahlia
  - 🟡 **40% - 79%**: Warm Golden Dahlia
  - 🔴 **0% - 39%**: Pulsing Red Dahlia with smooth animation
- **Multiple Visual Styles**: Choose between *The Dahlia*, *Neon*, *Classic*, *Minimal*, and *Standard*.
- **Multi-Format Android Widgets**:
  - `1x1 Compact`: Single-cell tile displaying percentage and skin icon.
  - `2x2 Standard`: Balanced tile with percentage, temperature, voltage, and charge state.
  - `4x1 Banner`: Wide widget displaying telemetry details, charging status, and live values.
- **Live Hardware Telemetry**: Percentage, temperature (°C/°F), voltage (V), health state, and battery chemistry technology.
- **Smart Charge Alert**: Configurable in-app notification when reaching 80%, 90%, or 100% charge to encourage battery longevity.
- **Configurable Settings**: Temperature unit toggle, ambient glow toggle, and foreground refresh intervals.

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

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Deflomick/dahlia_battery_widget.git
   cd dahlia_battery_widget
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code verification**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch on Android**:
   ```bash
   flutter run
   ```

---

## ⚠️ Disclaimer

This is an unofficial, non-commercial fan-made project created strictly for personal and educational purposes.

*Honkai: Star Rail*, its characters, designs, names, and all associated intellectual properties belong to their respective owners (**HoYoverse / miHoYo Co., Ltd.**). This application is not affiliated with, endorsed by, or sponsored by HoYoverse.

---

## 📄 License

The software code in this repository is licensed under the [MIT License](LICENSE).
