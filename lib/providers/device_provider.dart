import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/device.dart';
import '../services/ha_rest_service.dart';
import '../services/ha_ws_client.dart';

class DeviceProvider extends ChangeNotifier {
  List<Device> _devices = List<Device>.from(kInitialDevices);
  String? syncError;

  final HaRestService _rest;
  final HaWsClient _ws = HaWsClient();
  Timer? _pollTimer;
  bool _disposed = false;
  bool _initialWsSubscribed = false;

  List<Device> get devices => List.unmodifiable(_devices);

  DeviceProvider({required String haUrl, required String haToken})
      : _rest = HaRestService(baseUrl: haUrl, token: haToken) {
    _init();
  }

  // ---------------------------------------------------------------------------
  // Init & sync
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    try {
      await _ws.connect(_rest.baseUrl, _rest.token);
      if (_disposed) return;

      final states = await _ws.getStates();
      _applyStates(states.cast<Map<String, dynamic>>());

      await _ws.subscribeStateChanged(_onStateChanged);
      _initialWsSubscribed = true;
    } catch (_) {
      if (!kIsWeb) {
        await _syncRest();
      }
    }

    _startRecoveryLoop();
  }

  void _onStateChanged({
    required String entityId,
    required Map<String, dynamic>? newState,
    required Map<String, dynamic>? oldState,
  }) {
    if (newState == null || entityId.isEmpty) return;
    _devices = _devices.map((d) {
      if (d.entityId == entityId) return _applyHaState(d, newState);
      if (d.type == DeviceType.aircon && d.climateEntityId == entityId) {
        return _applyClimateState(d, newState);
      }
      return d;
    }).toList();
    notifyListeners();
  }

  void _startRecoveryLoop() {
    _pollTimer ??=
        Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_disposed) return;

      if (_ws.isConnected) {
        if (syncError != null) {
          syncError = null;
          notifyListeners();
        }
        return;
      }

      // Try to restore realtime via WebSocket first (works on mobile + web).
      try {
        await _ws.connect(_rest.baseUrl, _rest.token);
        if (_disposed) return;

        final states = await _ws.getStates();
        if (_disposed) return;
        _applyStates(states.cast<Map<String, dynamic>>());

        // Re-subscribe after reconnect.
        await _ws.subscribeStateChanged(_onStateChanged);
        _initialWsSubscribed = true;
        if (syncError != null) {
          syncError = null;
          notifyListeners();
        }
        return;
      } catch (_) {
        // Ignore and fall back to REST below (if possible).
      }

      if (!kIsWeb) {
        await _syncRest();
      } else if (_initialWsSubscribed == false) {
        syncError =
            'WebSocket connection failed. If running in browser, set up HTTPS and allow this origin in Home Assistant CORS.';
        notifyListeners();
      }
    });
  }

  Future<void> _syncRest() async {
    try {
      final states = await _rest.getAllStates();
      _applyStates(states
          .map((s) => {
                'entity_id': s.entityId,
                'state': s.state,
                'attributes': s.attributes,
              })
          .toList());
      if (syncError != null) {
        syncError = null;
        notifyListeners();
      }
    } catch (e) {
      syncError = e.toString();
      notifyListeners();
      Future.delayed(const Duration(seconds: 5), () {
        if (!_disposed) {
          syncError = null;
          notifyListeners();
        }
      });
    }
  }

  void _applyStates(List<Map<String, dynamic>> states) {
    final byId = <String, Map<String, dynamic>>{
      for (final s in states) s['entity_id'] as String: s,
    };
    _devices = _devices.map((d) {
      if (d.entityId != null && byId.containsKey(d.entityId)) {
        return _applyHaState(d, byId[d.entityId]!);
      }
      if (d.type == DeviceType.aircon &&
          d.climateEntityId != null &&
          byId.containsKey(d.climateEntityId)) {
        return _applyClimateState(d, byId[d.climateEntityId!]!);
      }
      return d;
    }).toList();
    notifyListeners();
  }

  Device _applyHaState(Device d, Map<String, dynamic> state) {
    final st = (state['state'] as String?) ?? '';
    final attrs = (state['attributes'] as Map<String, dynamic>?) ?? {};
    if (d.type == DeviceType.light) {
      final on = st.toLowerCase() == 'on';
      final brightness = HaRestService.lightBrightness(attrs);
      return d.copyWith(status: on, value: brightness ?? d.value);
    }
    if (d.type == DeviceType.curtain) {
      final mapped = HaRestService.coverStateToStatus(st);
      double? v;
      if (attrs['current_position'] is num) {
        v = (attrs['current_position'] as num).toDouble();
      } else if (attrs['current_tilt_position'] is num) {
        v = (attrs['current_tilt_position'] as num).toDouble();
      }
      return d.copyWith(
        status: mapped ?? d.status,
        value: v ?? d.value,
      );
    }
    if (d.type == DeviceType.fan) {
      final on = st.toLowerCase() == 'on';
      double? speed;
      if (attrs['percentage'] is num) {
        final pct = (attrs['percentage'] as num).toDouble();
        if (pct <= 0) {
          speed = 0;
        } else if (pct <= 33) {
          speed = 1;
        } else if (pct <= 66) {
          speed = 2;
        } else {
          speed = 3;
        }
      }
      return d.copyWith(
        status: on,
        value: speed ?? (on ? (d.value ?? 1) : 0),
      );
    }
    return d;
  }

  Device _applyClimateState(Device d, Map<String, dynamic> state) {
    final attrs = (state['attributes'] as Map<String, dynamic>?) ?? {};
    final hvacMode =
        ((attrs['hvac_mode'] as String?) ?? (state['state'] as String?) ?? '').toLowerCase();
    final on = hvacMode != 'off' && hvacMode.isNotEmpty;
    AirconMode? mode;
    if (hvacMode == 'auto') mode = AirconMode.auto;
    if (hvacMode == 'cool') mode = AirconMode.cool;
    return d.copyWith(status: on, airconMode: mode);
  }

  // ---------------------------------------------------------------------------
  // Device control
  // ---------------------------------------------------------------------------

  Future<void> toggleDevice(String id, {bool? forceState}) async {
    final device = _devices.firstWhere((d) => d.id == id);
    final target = forceState ?? !device.status;

    if (device.type == DeviceType.curtain) {
      await _applyCurtainPercent(device, target ? 100.0 : 0.0);
      return;
    }

    if (device.type == DeviceType.light && device.entityId != null) {
      _updateDevice(id, (d) => d.copyWith(status: target));
      try {
        final isSwitch = device.entityId!.startsWith('switch.');
        final domain = isSwitch ? 'switch' : 'light';
        await _callService(domain, target ? 'turn_on' : 'turn_off',
            {'entity_id': device.entityId!});
      } catch (_) {
        _updateDevice(id, (d) => d.copyWith(status: device.status));
      }
      return;
    }

    if (device.type == DeviceType.aircon) {
      final sceneId = target ? device.sceneTurnOn : device.sceneTurnOff;
      if (sceneId == null) return;
      _updateDevice(id, (d) => d.copyWith(status: target));
      try {
        await _callService('scene', 'turn_on', {'entity_id': sceneId});
      } catch (_) {
        _updateDevice(id, (d) => d.copyWith(status: device.status));
      }
      return;
    }

    if (device.type == DeviceType.fan) {
      if (device.entityId == null) return;
      _updateDevice(id, (d) => d.copyWith(status: target, value: target ? 1 : 0));
      try {
        await _callService('fan', target ? 'turn_on' : 'turn_off', {
          'entity_id': device.entityId!,
        });
      } catch (_) {
        _updateDevice(id, (d) => d.copyWith(status: device.status, value: device.value));
      }
      return;
    }

    _updateDevice(id, (d) => d.copyWith(status: target));
  }

  Future<void> _applyCurtainPercent(Device device, double percent) async {
    final p = percent.clamp(0.0, 100.0);
    _updateDevice(device.id, (d) => d.copyWith(status: p > 0, value: p));
    try {
      if (device.entityId != null) {
        await _callService(
          'cover',
          p > 0 ? 'open_cover' : 'close_cover',
          {'entity_id': device.entityId!},
        );
      } else {
        final sceneId =
            p > 0 ? device.sceneCurtainOpen : device.sceneCurtainClose;
        if (sceneId == null) return;
        await _callService('scene', 'turn_on', {'entity_id': sceneId});
      }
    } catch (_) {
      _updateDevice(
          device.id, (d) => d.copyWith(status: device.status, value: device.value));
    }
  }

  Future<void> setCurtainPreset(String id, double percent) async {
    final device = _devices.firstWhere((d) => d.id == id);
    await _applyCurtainPercent(device, percent);
  }

  Future<void> setCurtainPosition(String id, double value) async {
    final device = _devices.firstWhere((d) => d.id == id);
    await _applyCurtainPercent(device, value);
  }

  Future<void> triggerCurtainScene(String id, String action) async {
    final device = _devices.firstWhere((d) => d.id == id);
    String? sceneId;
    switch (action) {
      case 'open':
        sceneId = device.sceneCurtainOpen;
        break;
      case 'stop':
        sceneId = device.sceneCurtainStop;
        break;
      case 'close':
        sceneId = device.sceneCurtainClose;
        break;
      case 'tilt':
        sceneId = device.sceneCurtainTilt;
        break;
      case 'untilt':
        sceneId = device.sceneCurtainUntilt;
        break;
    }
    if (sceneId == null) return;
    await _callService('scene', 'turn_on', {'entity_id': sceneId});
  }

  Future<void> toggleAllLights({required bool turnOn}) async {
    final lights = _devices.where((d) => d.type == DeviceType.light).toList();
    for (final light in lights) {
      if (light.entityId == null) continue;
      _updateDevice(light.id, (d) => d.copyWith(status: turnOn));
      try {
        final domain = light.entityId!.startsWith('switch.') ? 'switch' : 'light';
        await _callService(domain, turnOn ? 'turn_on' : 'turn_off',
            {'entity_id': light.entityId!});
      } catch (_) {
        _updateDevice(light.id, (d) => d.copyWith(status: light.status));
      }
    }
  }

  bool get anyLightOn =>
      _devices.any((d) => d.type == DeviceType.light && d.status);

  bool get anyFanOn =>
      _devices.any((d) => d.type == DeviceType.fan && d.status);

  Future<void> toggleAllFans({required bool turnOn}) async {
    final fans = _devices.where((d) => d.type == DeviceType.fan).toList();
    for (final fan in fans) {
      if (fan.entityId == null) continue;
      _updateDevice(
        fan.id,
        (d) => d.copyWith(status: turnOn, value: turnOn ? (d.value ?? 1) : 0),
      );
      try {
        await _callService('fan', turnOn ? 'turn_on' : 'turn_off', {
          'entity_id': fan.entityId!,
        });
      } catch (_) {
        _updateDevice(fan.id, (d) => d.copyWith(status: fan.status, value: fan.value));
      }
    }
  }

  Future<void> setAllFansSpeed(int speed) async {
    final clampedSpeed = speed.clamp(1, 3);
    final percentage = (clampedSpeed * 33).clamp(1, 100);
    final fans = _devices.where((d) => d.type == DeviceType.fan).toList();
    for (final fan in fans) {
      if (fan.entityId == null) continue;
      _updateDevice(
        fan.id,
        (d) => d.copyWith(status: true, value: clampedSpeed.toDouble()),
      );
      try {
        await _callService('fan', 'set_percentage', {
          'entity_id': fan.entityId!,
          'percentage': percentage,
        });
      } catch (_) {
        _updateDevice(fan.id, (d) => d.copyWith(status: fan.status, value: fan.value));
      }
    }
  }

  // Blinds controls
  bool get anyBlindOpen =>
      _devices.any((d) => d.type == DeviceType.curtain && d.status);

  Future<void> openAllBlinds() async {
    final blinds = _devices.where((d) => d.type == DeviceType.curtain).toList();
    for (final blind in blinds) {
      _updateDevice(blind.id, (d) => d.copyWith(status: true, value: 100.0));
      try {
        if (blind.entityId != null) {
          await _callService('cover', 'open_cover', {'entity_id': blind.entityId!});
        } else if (blind.sceneCurtainOpen != null) {
          await _callService('scene', 'turn_on', {'entity_id': blind.sceneCurtainOpen!});
        }
      } catch (_) {
        _updateDevice(blind.id, (d) => d.copyWith(status: blind.status, value: blind.value));
      }
    }
  }

  Future<void> stopAllBlinds() async {
    final blinds = _devices.where((d) => d.type == DeviceType.curtain).toList();
    for (final blind in blinds) {
      try {
        if (blind.entityId != null) {
          await _callService('cover', 'stop_cover', {'entity_id': blind.entityId!});
        } else if (blind.sceneCurtainStop != null) {
          await _callService('scene', 'turn_on', {'entity_id': blind.sceneCurtainStop!});
        }
      } catch (_) {
        // Handle error, maybe revert state or show a message
      }
    }
  }

  Future<void> closeAllBlinds() async {
    final blinds = _devices.where((d) => d.type == DeviceType.curtain).toList();
    for (final blind in blinds) {
      _updateDevice(blind.id, (d) => d.copyWith(status: false, value: 0.0));
      try {
        if (blind.entityId != null) {
          await _callService('cover', 'close_cover', {'entity_id': blind.entityId!});
        } else if (blind.sceneCurtainClose != null) {
          await _callService('scene', 'turn_on', {'entity_id': blind.sceneCurtainClose!});
        }
      } catch (_) {
        _updateDevice(blind.id, (d) => d.copyWith(status: blind.status, value: blind.value));
      }
    }
  }

  Future<void> tiltAllBlinds() async {
    final blinds = _devices.where((d) => d.type == DeviceType.curtain).toList();
    for (final blind in blinds) {
      if (blind.sceneCurtainTilt == null) continue;
      try {
        await _callService('scene', 'turn_on', {'entity_id': blind.sceneCurtainTilt!});
      } catch (_) {
        // Handle error
      }
    }
  }

  Future<void> straightenAllBlinds() async {
    final blinds = _devices.where((d) => d.type == DeviceType.curtain).toList();
    for (final blind in blinds) {
      if (blind.sceneCurtainUntilt == null) continue;
      try {
        await _callService('scene', 'turn_on', {'entity_id': blind.sceneCurtainUntilt!});
      } catch (_) {
        // Handle error
      }
    }
  }

  Future<void> triggerAirconScene(String id, String sceneEntityId,
      {AirconMode? mode}) async {
    if (mode != null) {
      _updateDevice(id, (d) => d.copyWith(airconMode: mode));
    }
    try {
      await _callService('scene', 'turn_on', {'entity_id': sceneEntityId});
    } catch (_) {}
  }

  Future<void> triggerFanSpeed(String id, int speed) async {
    final device = _devices.firstWhere((d) => d.id == id);
    if (device.entityId == null) return;
    final clampedSpeed = speed.clamp(1, 3);
    final percentage = (clampedSpeed * 33).clamp(1, 100);
    _updateDevice(id, (d) => d.copyWith(status: true, value: speed.toDouble()));
    try {
      await _callService('fan', 'set_percentage', {
        'entity_id': device.entityId!,
        'percentage': percentage,
      });
    } catch (_) {
      _updateDevice(id, (d) => d.copyWith(status: device.status, value: device.value));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _updateDevice(String id, Device Function(Device) fn) {
    _devices = _devices.map((d) => d.id == id ? fn(d) : d).toList();
    notifyListeners();
  }

  Future<void> _callService(
      String domain, String service, Map<String, dynamic> data) async {
    if (_ws.isConnected) {
      await _ws.callService(domain, service, data);
    } else {
      if (kIsWeb) {
        throw Exception(
            'WebSocket disconnected on web; REST fallback is blocked by CORS unless HA is configured.');
      }
      await _rest.callService(domain, service, data);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _ws.close();
    super.dispose();
  }
}
