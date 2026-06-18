import 'package:flutter/material.dart';
import 'models/device.dart';

// ---------------------------------------------------------------------------
// Floor plan IoT icon palette (from mobile gradient blue → purple)
// ---------------------------------------------------------------------------

const Color kIotOn = Color(0xFFCBDAF2);
const Color kIotOff = Color(0xFF8499BE);
const Color kIotGlowBlue = Color(0xFF03275F);
const Color kIotGlowPurple = Color(0xFF2F0943);

// Desktop floor plan background gradient (sidebar uses same family)
const Color kDesktopGradientStart = Color(0xFF1E1B4B);
const Color kDesktopGradientMid = Color(0xFF312E81);
const Color kDesktopGradientEnd = Color(0xFF4C1D95);

const LinearGradient kDesktopBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kDesktopGradientStart, kDesktopGradientMid, kDesktopGradientEnd],
);

/// Black glass sidebar + vivid control button accents.
const Color kSidebarBlackTop = Color(0xFF121216);
const Color kSidebarBlackBottom = Color(0xFF060608);

const Color kBtnAccentLight = Color(0xFFFBBF24);
// Match DeviceCard palette (All Devices)
const Color kBtnAccentFan = Color(0xFF60A5FA);
const Color kBtnAccentBlind = Color(0xFFC084FC);
const Color kBtnAccentAircon = Color(0xFF67E8F9);
const Color kBtnAccentMuted = Color(0xFF6B7280);
const Color kBtnAccentConnected = Color(0xFF4ADE80);

// Optional borders (also used in All Devices widgets)
const Color kBtnBorderFan = Color(0xFF93C5FD);
const Color kBtnBorderBlind = Color(0xFFD8B4FE);

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

const List<Device> kInitialDevices = [
  // Lights — x,y = desktop (floor_plan_desktop.png)
  // Tablet coords → kLightTabletCoords

//signage
 //signage
 Device(id: 'l13', name: 'Indoor Signage', type: DeviceType.light, status: false, room: 'Indoor Signage', x: 31.3, y: 39.3, entityId: 'switch.indoor_signage_socket_1'),
 Device(id: 'l14', name: 'Outdoor Signage', type: DeviceType.light, status: false, room: 'Outdoor Signage', x: 44.3, y: 15.9, entityId: 'switch.ronnel_plug_socket_1'),
  // Front door
  Device(id: 'l8', name: 'Front door 1', type: DeviceType.light, status: false, room: 'Front door', x: 26.1, y: 35.5, entityId: 'switch.m8_pro_swich_6_switch_1'),
  Device(id: 'l9', name: 'Front door 2', type: DeviceType.light, status: false, room: 'Front door', x: 28.6, y: 37.3, entityId: 'switch.m8_pro_swich_6_switch_2'),

  // Lobby
  Device(id: 'l6', name: 'Lobby 1', type: DeviceType.light, status: false, room: 'Lobby', x: 37.1, y: 29.2, entityId: 'switch.m8_pro_swich_6_switch_3'),
  Device(id: 'l7', name: 'Lobby 2', type: DeviceType.light, status: false, room: 'Lobby', x: 39.5, y: 31.9, entityId: 'switch.m8_pro_swich_6_switch_4'),
  Device(id: 'l11', name: 'Lobby 3', type: DeviceType.light, status: false, room: 'Lobby', x: 41.9, y: 34.5, entityId: 'switch.light_switch_breaker_side_1_switch_4'),
  Device(id: 'l12', name: 'Bulb Lamp', type: DeviceType.light, status: false, room: 'Lobby', x: 41.4, y: 24.9, entityId: 'switch.smart_plug_bulb_lamp_socket_1'),

  // Carlo / Joe
  Device(id: 'l1', name: 'Sir Carlo Lamp', type: DeviceType.light, status: false, room: 'Office', x: 43.3, y: 44.8, entityId: 'light.carlo_desk'),
  Device(id: 'l2', name: 'Boss Joe Desk', type: DeviceType.light, status: false, room: 'Office', x: 51.1, y: 35.6, entityId: 'switch.light_switch_breaker_side_2_switch_1'),

  // Dev Team
  Device(id: 'l5', name: 'Dev Team – Switch Front', type: DeviceType.light, status: false, room: 'Dev Team', x: 43, y: 54.1, entityId: 'switch.light_switch_breaker_side_2_switch_4'),
  // Device(id: 'l10', name: 'Ronnel Lamp', type: DeviceType.light, status: false, room: 'Dev Team', x: 40.7, y: 54.5, lightIcon: LightIcon.lamp, entityId: 'light.ronnel'),
  Device(id: 'l4', name: 'Dev Team – Switch Middle', type: DeviceType.light, status: false, room: 'Dev Team', x: 49.1, y: 61.4, entityId: 'switch.light_switch_breaker_side_2_switch_3'),
  Device(id: 'l3', name: 'Dev Team – Switch Back', type: DeviceType.light, status: false, room: 'Dev Team', x: 56.8, y: 70.6, entityId: 'switch.light_switch_breaker_side_2_switch_2'),

  // Curtains
  Device(
    id: 'c1',
    name: 'Blinds front door',
    type: DeviceType.curtain,
    status: true,
    room: 'Front door',
    x: 84, y: 74,
    entityId: 'cover.office_curtain_front_door_curtain',
    sceneCurtainOpen: 'scene.curtain_fdoor_open',
    sceneCurtainStop: 'scene.curtain_fdoor_stop',
    sceneCurtainClose: 'scene.curtain_fdoor_close',
    sceneCurtainTilt: 'scene.curtain_fdoor_tilt',
    sceneCurtainUntilt: 'scene.curtain_fdoor_untilt',
  ),
  Device(
    id: 'c2',
    name: 'Blinds Lobby',
    type: DeviceType.curtain,
    status: false,
    room: 'Lobby',
    x: 58, y: 64,
    entityId: 'cover.office_curtain_front_right_side_curtain',
    sceneCurtainOpen: 'scene.curtain_lobby_open',
    sceneCurtainStop: 'scene.curtain_lobby_stop',
    sceneCurtainClose: 'scene.curtain_lobby_close',
    sceneCurtainTilt: 'scene.curtain_lobby_tilt',
    sceneCurtainUntilt: 'scene.curtain_lobby_untilt',
  ),
  Device(
    id: 'c3',
    name: 'Blinds Back',
    type: DeviceType.curtain,
    status: false,
    room: 'Dev Team',
    x: 64, y: 36,
    entityId: 'cover.office_curtain_back_curtain',
    sceneCurtainOpen: 'scene.curtain_back_open',
    sceneCurtainStop: 'scene.curtain_back_stop',
    sceneCurtainClose: 'scene.curtain_back_close',
    sceneCurtainTilt: 'scene.curtain_back_tilt',
    sceneCurtainUntilt: 'scene.curtain_back_untilt',
  ),

  // Aircon
  Device(
    id: 'ac2',
    name: 'Lobby Aircon',
    type: DeviceType.aircon,
    status: false,
    room: 'Lobby',
    x: 48, y: 10.5,
    sceneTurnOn: 'scene.aircon_lobby_on',
    sceneTurnOff: 'scene.aircon_lobby_turn_off',
    sceneAuto: 'scene.aircon_lobby_auto',
    sceneCool: 'scene.aircon_lobby_cool',
  ),

  // Fans
  Device(
    id: 'f1',
    name: 'Fan',
    type: DeviceType.fan,
    status: false,
    room: 'Lobby',
    x: 20,
    y: 22,
    entityId: 'fan.lobby_ceiling_fan',
  ),
  Device(
    id: 'f2',
    name: 'Fan',
    type: DeviceType.fan,
    status: false,
    room: 'Front door',
    x: 50,
    y: 31,
    entityId: 'fan.front_door_ceiling_fan',
  ),
  Device(
    id: 'f3',
    name: 'Fan 1',
    type: DeviceType.fan,
    status: false,
    room: 'Dev Team',
    x: 34,
    y: 57,
    entityId: 'fan.dev_team_fan_1',
  ),
  Device(
    id: 'f4',
    name: 'Fan 2',
    type: DeviceType.fan,
    status: false,
    room: 'Dev Team',
    x: 44,
    y: 66,
    entityId: 'fan.dev_team_fan_2',
  ),
];

// ---------------------------------------------------------------------------
// Floor plan — desktop overlay positions (% of container)
// ---------------------------------------------------------------------------

class CurtainPos {
  final double left;
  final double top;
  final double width;
  const CurtainPos({required this.left, required this.top, this.width = 14});
}

const Map<String, CurtainPos> kCurtainDesktopCoords = {
  'c1': CurtainPos(left: 23.4, top: 27.4, width: 13), // Blinds front door
  'c2': CurtainPos(left: 40.9, top: 13.7, width: 16.2),   // Blinds Lobby
  'c3': CurtainPos(left: 62, top: 70.5, width: 19.7), // Blinds Back
};

/// Desktop marker rotation in degrees (0 = upright).
const Map<String, double> kDesktopMarkerRotation = {
  'l13': 0,
  'l14': 0,
  'l8': 0,
  'l9': 0,
  'l6': 0,
  'l7': 0,
  'l11': 0,
  'l12': 0,
  'l1': 0,
  'l2': 0,
  'l5': 0,
  'l4': 0,
  'l3': 0,
  'f1': 0,
  'f2': 0,
  'f3': 0,
  'f4': 0,
  'ac2': 3.4,
  'c1': 154.3,
  'c2': 154.3,
  'c3': 147.4,
};

// ---------------------------------------------------------------------------
// Floor plan — tablet overlay positions (% of container)
// Adjust these values to match Floor_Plan_tablet.png
// ---------------------------------------------------------------------------

const Map<String, CurtainPos> kCurtainTabletCoords = {
  'c1': CurtainPos(left: 26, top: 3.8, width: 29.5), // Curtain front door
  'c2': CurtainPos(left: 72.5, top: 3.8, width: 42), // Curtain Lobby
  'c3': CurtainPos(left: 29, top: 95.5,   width: 48.5), // Curtain Back
};

const Map<String, Offset> kLightTabletCoords = {
  // Signage
  'l13': Offset(27, 22.5),    // Indoor Signage
  'l14': Offset(75, 7),    // Outdoor Signage

  // Front door
  'l8': Offset(28, 12),    // Front door 1
  'l9': Offset(28, 17.5),    // Front door 2
  'l12': Offset(61, 16.5),   // Bulb Lamp

  // Lobby
  'l6': Offset(48, 12),    // Lobby 1
  'l7': Offset(48, 18.5),    // Lobby 2
  'l11': Offset(48, 25.5),   // lobby 3

  // Carlo / Joe
  'l1': Offset(39, 38),      // Sir Carlo Lamp
  'l2': Offset(65, 38),      // Boss Joe Desk

  // Dev Team — centered on left-row desk monitors
  'l5': Offset(28.5, 50),      // Front
  // 'l10': Offset(25.5, 62),     // Ronnel Lamp
  'l4': Offset(28.5, 65.7),      // Middle
  'l3': Offset(28.5, 83),      // Back
};

const Map<String, Offset> kFanDesktopCoords = {
  'f1': Offset(44.1, 27.7),   // Lobby Fan
  'f2': Offset(27.3, 43.3),   // Front Door Fan
  'f3': Offset(46.3, 56.9),   // Dev-Team Fan 1
  'f4': Offset(53.2, 65.9),   // Dev-Team Fan 2
};

const Map<String, Offset> kFanTabletCoords = {
  'f1': Offset(21, 20.5), // Lobby Fan
  'f2': Offset(63, 24.5),     // Front Door Fan
  'f3': Offset(29.7, 58),     // Dev-Team Fan 1
  'f4': Offset(29.7, 75),     // Dev-Team Fan 2
};

const Map<String, Offset> kAirconTabletCoords = {
  'ac2': Offset(89.5, 6.8), // Lobby Aircon
};

/// Mobile/tablet marker rotation in degrees (0 = default horizontal bar).
/// Only list markers that need rotation — curtains stay 0 on mobile.
const Map<String, double> kMobileMarkerRotation = {
  'ac2': 60, // Lobby Aircon — tune in constants.dart
};

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> kPeople = [
  {'id': 'p1', 'name': 'Marcus', 'avatar': 'https://picsum.photos/seed/marcus/100/100', 'atHome': true},
  {'id': 'p2', 'name': 'Elena', 'avatar': 'https://picsum.photos/seed/elena/100/100', 'atHome': true},
  {'id': 'p3', 'name': 'Ghost', 'avatar': 'https://picsum.photos/seed/ghost/100/100', 'atHome': false},
];
