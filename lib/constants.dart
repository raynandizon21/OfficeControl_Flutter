import 'package:flutter/material.dart';
import 'models/device.dart';

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

const List<Device> kInitialDevices = [
  // Lights — x,y = desktop (floor_plan_desktop.png)
  // Tablet coords → kLightTabletCoords

  // Front door
  Device(id: 'l8', name: 'Front door 1', type: DeviceType.light, status: false, room: 'Front door', x: 20, y: 20, entityId: 'switch.light_switch_front_door_2_switch_4'),
  Device(id: 'l9', name: 'Front door 2', type: DeviceType.light, status: false, room: 'Front door', x: 44, y: 25, entityId: 'switch.light_switch_front_door_2_switch_3'),

  // Lobby
  Device(id: 'l6', name: 'Lobby 1', type: DeviceType.light, status: false, room: 'Lobby', x: 55.5, y: 21, entityId: 'switch.light_switch_front_door_2_switch_2'),
  Device(id: 'l7', name: 'Lobby 2', type: DeviceType.light, status: false, room: 'Lobby', x: 55.5, y: 25, entityId: 'switch.light_switch_front_door_2_switch_1'),
  Device(id: 'l11', name: 'Lobby 3', type: DeviceType.light, status: false, room: 'Lobby', x: 55.5, y: 29, entityId: 'switch.light_switch_breaker_side_1_switch_4'),

  // Carlo / Joe
  Device(id: 'l1', name: 'Sir Carlo Lamp', type: DeviceType.light, status: false, room: 'Office', x: 51, y: 32, lightIcon: LightIcon.lamp, entityId: 'light.carlo_desk'),
  Device(id: 'l2', name: 'Boss Joe Desk', type: DeviceType.light, status: false, room: 'Office', x: 58, y: 32, entityId: 'switch.light_switch_breaker_side_2_switch_1'),

  // Dev Team
  Device(id: 'l5', name: 'Dev Team – Switch Front', type: DeviceType.light, status: false, room: 'Dev Team', x: 44, y: 50, entityId: 'switch.light_switch_breaker_side_2_switch_4'),
  Device(id: 'l10', name: 'Ronnel Lamp', type: DeviceType.light, status: false, room: 'Dev Team', x: 40.7, y: 54.5, lightIcon: LightIcon.lamp, entityId: 'light.ronnel'),
  Device(id: 'l4', name: 'Dev Team – Switch Middle', type: DeviceType.light, status: false, room: 'Dev Team', x: 44, y: 62, entityId: 'switch.light_switch_breaker_side_2_switch_3'),
  Device(id: 'l3', name: 'Dev Team – Switch Back', type: DeviceType.light, status: false, room: 'Dev Team', x: 44, y: 73, entityId: 'switch.light_switch_breaker_side_2_switch_2'),

  // Curtains
  Device(
    id: 'c1',
    name: 'Blinds front door',
    type: DeviceType.curtain,
    status: true,
    room: 'Front door',
    x: 84, y: 74,
    entityId: 'cover.office_curtain_front_door_curtain',
    sceneCurtainOpen: 'scene.curtain_front_door_open',
    sceneCurtainStop: 'scene.curtain_front_door_stop',
    sceneCurtainClose: 'scene.curtain_front_door_close',
    sceneCurtainTilt: 'scene.curtain_front_door_tilt',
    sceneCurtainUntilt: 'scene.curtain_front_door_untilt',
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
    x: 63, y: 67,
    sceneTurnOn: 'scene.aircon_lobby_on',
    sceneTurnOff: 'scene.aircon_lobby_turn_off',
    sceneAuto: 'scene.aircon_lobby_auto',
    sceneCool: 'scene.aircon_lobby_cool',
  ),
  Device(
    id: 'ac1',
    name: 'Dev Team Aircon',
    type: DeviceType.aircon,
    status: false,
    room: 'Dev Team',
    x: 72, y: 30,
    sceneTurnOn: 'scene.dev_team_aircon_turn_on',
    sceneTurnOff: 'scene.dev_team_aircon_turn_off',
    sceneAuto: 'scene.dev_team_aircon_auto',
    sceneCool: 'scene.dev_team_aircon_cool',
    climateEntityId: 'climate.dev_team_aircon',
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
  'c1': CurtainPos(left: 44.9, top: 10.5, width: 11.5), // Curtain front door
  'c2': CurtainPos(left: 58.7, top: 10.5, width: 14),   // Curtain Lobby
  'c3': CurtainPos(left: 43.9, top: 91,   width: 15.4), // Curtain Back
};

// ---------------------------------------------------------------------------
// Floor plan — tablet overlay positions (% of container)
// Adjust these values to match Floor_Plan_tablet.png
// ---------------------------------------------------------------------------

const Map<String, CurtainPos> kCurtainTabletCoords = {
  'c1': CurtainPos(left: 31, top: 8.4, width: 32.5), // Curtain front door
  'c2': CurtainPos(left: 69.5, top: 8.4, width: 40), // Curtain Lobby
  'c3': CurtainPos(left: 28, top: 92.8,   width: 43.5), // Curtain Back
};

const Map<String, Offset> kLightTabletCoords = {
  // Front door
  'l8': Offset(29, 20),    // Front door 1
  'l9': Offset(29, 25),    // Front door 2

  // Lobby
  'l6': Offset(58, 20),    // Lobby 1
  'l7': Offset(58, 25),    // Lobby 2
  'l11': Offset(58, 29.7),   // lobby 3

  // Carlo / Joe
  'l1': Offset(47, 30.5),      // Sir Carlo Lamp
  'l2': Offset(69, 30.5),      // Boss Joe Desk

  // Dev Team
  'l5': Offset(29, 50),      // Dev Team – Switch Front
  'l4': Offset(29, 62),      // Dev Team – Switch Middle
  'l3': Offset(29, 73),      // Dev Team – Switch Back
  'l10': Offset(19.7, 54.5), // Ronnel Lamp
};

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> kPeople = [
  {'id': 'p1', 'name': 'Marcus', 'avatar': 'https://picsum.photos/seed/marcus/100/100', 'atHome': true},
  {'id': 'p2', 'name': 'Elena', 'avatar': 'https://picsum.photos/seed/elena/100/100', 'atHome': true},
  {'id': 'p3', 'name': 'Ghost', 'avatar': 'https://picsum.photos/seed/ghost/100/100', 'atHome': false},
];
