import 'package:flutter/material.dart';
import 'models/device.dart';

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

const List<Device> kInitialDevices = [
  // Lights — x,y = desktop (floor_plan_desktop.png)
  // Tablet coords → kLightTabletCoords

//signage
 //signage
 Device(id: 'l13', name: 'Indoor Signage', type: DeviceType.light, status: false, room: 'Indoor Signage', x: 55.5, y: 28, lightIcon: LightIcon.lightbulb, entityId: 'switch.indoor_signage_socket_1'),
 Device(id: 'l14', name: 'Outdoor Signage', type: DeviceType.light, status: false, room: 'Outdoor Signage', x: 75, y: 40, lightIcon: LightIcon.lightbulb, entityId: 'switch.ronnel_plug_socket_1'),
  // Front door
  Device(id: 'l8', name: 'Front door 1', type: DeviceType.light, status: false, room: 'Front door', x: 20, y: 17, entityId: 'switch.light_switch_front_door_2_switch_4'),
  Device(id: 'l9', name: 'Front door 2', type: DeviceType.light, status: false, room: 'Front door', x: 44, y: 22, entityId: 'switch.light_switch_front_door_2_switch_3'),

  // Lobby
  Device(id: 'l6', name: 'Lobby 1', type: DeviceType.light, status: false, room: 'Lobby', x: 55.5, y: 21, entityId: 'switch.light_switch_front_door_2_switch_2'),
  Device(id: 'l7', name: 'Lobby 2', type: DeviceType.light, status: false, room: 'Lobby', x: 55.5, y: 25, entityId: 'switch.light_switch_front_door_2_switch_1'),
  Device(id: 'l11', name: 'Lobby 3', type: DeviceType.light, status: false, room: 'Lobby', x: 55.5, y: 29, entityId: 'switch.light_switch_breaker_side_1_switch_4'),
  Device(id: 'l12', name: 'Bulb Lamp', type: DeviceType.light, status: false, room: 'Lobby', x: 32, y: 22, lightIcon: LightIcon.lamp, entityId: 'switch.light_switch_front_door_1_switch_1'),

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

  // Fans
  Device(
    id: 'f1',
    name: 'Fan',
    type: DeviceType.fan,
    status: false,
    room: 'Lobby',
    x: 50,
    y: 31,
    entityId: 'fan.lobby_ceiling_fan',
  ),
  Device(
    id: 'f2',
    name: 'Fan',
    type: DeviceType.fan,
    status: false,
    room: 'Front door',
    x: 20,
    y: 22,
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
  'c1': CurtainPos(left: 44.9, top: 10.5, width: 11.5), // Curtain front door
  'c2': CurtainPos(left: 58.7, top: 10.5, width: 14),   // Curtain Lobby
  'c3': CurtainPos(left: 43.9, top: 91,   width: 15.4), // Curtain Back
};

// ---------------------------------------------------------------------------
// Floor plan — tablet overlay positions (% of container)
// Adjust these values to match Floor_Plan_tablet.png
// ---------------------------------------------------------------------------

const Map<String, CurtainPos> kCurtainTabletCoords = {
  'c1': CurtainPos(left: 25, top: 5, width: 32.5), // Curtain front door
  'c2': CurtainPos(left: 68.5, top: 5.8, width: 49), // Curtain Lobby
  'c3': CurtainPos(left: 24.8, top: 95.5,   width: 42.5), // Curtain Back
};

const Map<String, Offset> kLightTabletCoords = {
  // Signage
  'l13': Offset(25, 28),    // Indoor Signage
  'l14': Offset(75, 11),    // Outdoor Signage

  // Front door
  'l8': Offset(26, 17),    // Front door 1
  'l9': Offset(26, 23),    // Front door 2
  'l12': Offset(60, 20),   // Bulb Lamp

  // Lobby
  'l6': Offset(48, 16.5),    // Lobby 1
  'l7': Offset(48, 21.5),    // Lobby 2
  'l11': Offset(48, 26.5),   // lobby 3

  // Carlo / Joe
  'l1': Offset(36, 38),      // Sir Carlo Lamp
  'l2': Offset(62, 38),      // Boss Joe Desk

  // Dev Team
  'l5': Offset(25, 52.5),      // Dev Team – Switch Front
  'l4': Offset(25, 70),      // Dev Team – Switch Middle
  'l3': Offset(25, 82),      // Dev Team – Switch Back
  'l10': Offset(21.5, 62.5), // Ronnel Lamp
};

const Map<String, Offset> kFanDesktopCoords = {
  'f1': Offset(50, 28),   // Lobby Fan
  'f2': Offset(20, 22),   // Front Door Fan
  'f3': Offset(33, 57),   // Dev-Team Fan 1
  'f4': Offset(51.5, 66),   // Dev-Team Fan 2
};

const Map<String, Offset> kFanTabletCoords = {
  'f1': Offset(60.6, 25.5), // Lobby Fan
  'f2': Offset(18, 23.5),     // Front Door Fan
  'f3': Offset(25.8, 58),     // Dev-Team Fan 1
  'f4': Offset(25.8, 76.5),     // Dev-Team Fan 2
};

const Map<String, Offset> kAirconTabletCoords = {
  'ac2': Offset(86.2, 10.7), // Lobby Aircon
};

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> kPeople = [
  {'id': 'p1', 'name': 'Marcus', 'avatar': 'https://picsum.photos/seed/marcus/100/100', 'atHome': true},
  {'id': 'p2', 'name': 'Elena', 'avatar': 'https://picsum.photos/seed/elena/100/100', 'atHome': true},
  {'id': 'p3', 'name': 'Ghost', 'avatar': 'https://picsum.photos/seed/ghost/100/100', 'atHome': false},
];
