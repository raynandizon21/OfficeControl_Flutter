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

## Home Assistant entities (OfficeControl)

Lahat ng IoT mappings ay naka-define sa `lib/constants.dart` (`kInitialDevices`). Ito ang buong listahan ng **entity IDs** na ginagamit ng app.

### `switch.*` (ginagamit bilang lights / toggles)

| App label | Entity |
|-----------|--------|
| Indoor Signage | `switch.indoor_signage_socket_1` |
| Outdoor Signage | `switch.ronnel_plug_socket_1` |
| Front door 1 | `switch.m8_pro_swich_6_switch_1` |
| Front door 2 | `switch.m8_pro_swich_6_switch_2` |
| Lobby 1 | `switch.m8_pro_swich_6_switch_3` |
| Lobby 2 | `switch.m8_pro_swich_6_switch_4` |
| Lobby 3 | `switch.light_switch_breaker_side_1_switch_4` |
| Bulb Lamp | `switch.smart_plug_bulb_lamp_socket_1` |
| Boss Joe Desk | `switch.light_switch_breaker_side_2_switch_1` |
| Dev Team – Switch Front | `switch.light_switch_breaker_side_2_switch_4` |
| Dev Team – Switch Middle | `switch.light_switch_breaker_side_2_switch_3` |
| Dev Team – Switch Back | `switch.light_switch_breaker_side_2_switch_2` |

### `light.*`

| App label | Entity |
|-----------|--------|
| Sir Carlo Lamp | `light.carlo_desk` |
| Ronnel Lamp | `light.ronnel` |

### `fan.*`

| App label | Entity |
|-----------|--------|
| Fan (Lobby) | `fan.lobby_ceiling_fan` |
| Fan (Front door) | `fan.front_door_ceiling_fan` |
| Fan 1 (Dev Team) | `fan.dev_team_fan_1` |
| Fan 2 (Dev Team) | `fan.dev_team_fan_2` |

### `cover.*` at curtain `scene.*`

| App label | Cover | Mga scene (open / stop / close / tilt / untilt) |
|-----------|-------|--------------------------------------------------|
| Blinds front door | `cover.office_curtain_front_door_curtain` | `scene.curtain_fdoor_open`, `scene.curtain_fdoor_stop`, `scene.curtain_fdoor_close`, `scene.curtain_fdoor_tilt`, `scene.curtain_fdoor_untilt` |
| Blinds Lobby | `cover.office_curtain_front_right_side_curtain` | `scene.curtain_lobby_open`, `scene.curtain_lobby_stop`, `scene.curtain_lobby_close`, `scene.curtain_lobby_tilt`, `scene.curtain_lobby_untilt` |
| Blinds Back | `cover.office_curtain_back_curtain` | `scene.curtain_back_open`, `scene.curtain_back_stop`, `scene.curtain_back_close`, `scene.curtain_back_tilt`, `scene.curtain_back_untilt` |

### Aircon — `scene.*` at `climate.*`

| App label | Mga scene (on / off / auto / cool) | State sync |
|-----------|-----------------------------------|-------------|
| Lobby Aircon | `scene.aircon_lobby_on`, `scene.aircon_lobby_turn_off`, `scene.aircon_lobby_auto`, `scene.aircon_lobby_cool` | — |
| Dev Team Aircon | `scene.dev_team_aircon_turn_on`, `scene.dev_team_aircon_turn_off`, `scene.dev_team_aircon_auto`, `scene.dev_team_aircon_cool` | `climate.dev_team_aircon` |

**Tandaan:** Ang listahan sa itaas ay **mga entity na nakabit sa OfficeControl lamang**. Ang buong HA instance ay maaaring may dagdag pang entities na wala sa app.

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
