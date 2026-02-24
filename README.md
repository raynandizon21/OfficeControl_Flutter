# OfficeControl — Flutter APK

Flutter rewrite ng OfficeControl React/Vite smart office dashboard.

## Requirements

- Flutter SDK 3.7+ (https://flutter.dev/docs/get-started/install)
- Android Studio + Android SDK (para sa APK build)
- Android tablet na may Android 5.0+

## Setup

### 1. Create the Flutter project scaffold

```powershell
cd d:\SYSTEM\OfficeControl_Flutter
flutter create . --project-name office_control
```

> Pinupunan lang nito ang `android/`, `ios/`, etc. — hindi nito ino-overwrite ang mga files sa `lib/`.

### 2. Install dependencies

```powershell
flutter pub get
```

### 3. Build APK

```powershell
flutter build apk --release
```

APK output: `build\app\outputs\flutter-apk\app-release.apk`

### 4. Install sa tablet

```powershell
flutter install
# o manu-mano i-copy ang APK sa tablet at i-install
```

---

## First-time setup sa tablet

1. Buksan ang app.
2. I-enter ang **Home Assistant URL** (e.g. `http://192.168.1.100:8123`).
3. I-enter ang **Long-lived Access Token** (mula sa HA Profile > Long-lived access tokens).
4. Tap **Connect**.

---

## Floor plan overlay adjustment

Para i-adjust ang posisyon ng mga bulbs at curtain lines sa tablet:

- **Light positions**: `lib/constants.dart` → `kLightTabletCoords`
- **Curtain line positions**: `lib/constants.dart` → `kCurtainTabletCoords`

---

## Project structure

```
lib/
  main.dart                    ← entry point
  constants.dart               ← devices + floor plan coords
  models/device.dart           ← Device, Room, Person models
  services/ha_rest_service.dart ← REST HTTP client
  services/ha_ws_client.dart   ← WebSocket client (HA protocol)
  providers/device_provider.dart ← state management + HA sync
  widgets/
    sidebar.dart               ← left nav, clock, temp
    floor_plan.dart            ← interactive floor plan
    device_grid.dart           ← filtered device list
    device_card.dart           ← individual device card
  screens/
    main_screen.dart           ← main layout
    settings_screen.dart       ← HA URL/token setup
assets/
  images/
    floor_plan_desktop.png     ← desktop floor plan
    floor_plan_tablet.png      ← tablet floor plan
```
