enum DeviceType { light, curtain, aircon }

enum AirconMode { auto, cool }

enum LightIcon { lightbulb, lamp }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final bool status;
  final double? value;
  final String room;
  final double x;
  final double y;
  final LightIcon? lightIcon;
  final String? entityId;
  final String? climateEntityId;
  final String? sceneTurnOn;
  final String? sceneTurnOff;
  final String? sceneAuto;
  final String? sceneCool;
  final String? sceneCurtainOpen;
  final String? sceneCurtainStop;
  final String? sceneCurtainClose;
  final String? sceneCurtainTilt;
  final String? sceneCurtainUntilt;
  final AirconMode? airconMode;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.value,
    required this.room,
    required this.x,
    required this.y,
    this.lightIcon,
    this.entityId,
    this.climateEntityId,
    this.sceneTurnOn,
    this.sceneTurnOff,
    this.sceneAuto,
    this.sceneCool,
    this.sceneCurtainOpen,
    this.sceneCurtainStop,
    this.sceneCurtainClose,
    this.sceneCurtainTilt,
    this.sceneCurtainUntilt,
    this.airconMode,
  });

  Device copyWith({
    bool? status,
    double? value,
    AirconMode? airconMode,
    bool clearAirconMode = false,
    bool clearValue = false,
  }) {
    return Device(
      id: id,
      name: name,
      type: type,
      status: status ?? this.status,
      value: clearValue ? null : (value ?? this.value),
      room: room,
      x: x,
      y: y,
      lightIcon: lightIcon,
      entityId: entityId,
      climateEntityId: climateEntityId,
      sceneTurnOn: sceneTurnOn,
      sceneTurnOff: sceneTurnOff,
      sceneAuto: sceneAuto,
      sceneCool: sceneCool,
      sceneCurtainOpen: sceneCurtainOpen,
      sceneCurtainStop: sceneCurtainStop,
      sceneCurtainClose: sceneCurtainClose,
      sceneCurtainTilt: sceneCurtainTilt,
      sceneCurtainUntilt: sceneCurtainUntilt,
      airconMode: clearAirconMode ? null : (airconMode ?? this.airconMode),
    );
  }

  bool get isOn {
    if (type == DeviceType.curtain) {
      return status || (value != null && value! > 0);
    }
    return status;
  }

  String get statusLabel {
    if (type == DeviceType.curtain) return isOn ? 'Open' : 'Closed';
    return status ? 'On' : 'Off';
  }

  bool get hasCurtainScenes =>
      sceneCurtainOpen != null ||
      sceneCurtainStop != null ||
      sceneCurtainClose != null ||
      sceneCurtainTilt != null ||
      sceneCurtainUntilt != null;
}

class Room {
  final String id;
  final String name;

  const Room({required this.id, required this.name});
}

class Person {
  final String id;
  final String name;
  final String avatar;
  final bool atHome;

  const Person({
    required this.id,
    required this.name,
    required this.avatar,
    required this.atHome,
  });
}
