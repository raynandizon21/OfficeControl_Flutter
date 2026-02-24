import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef StateChangedHandler = void Function({
  required String entityId,
  required Map<String, dynamic>? newState,
  required Map<String, dynamic>? oldState,
});

class HaWsClient {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  int _nextId = 1;
  final Map<int, Completer<dynamic>> _pending = {};
  final Map<int, void Function(Map<String, dynamic>)> _eventHandlers = {};
  bool _connected = false;

  bool get isConnected => _connected;

  String _toWsUrl(String haUrl) {
    final base = haUrl.replaceAll(RegExp(r'/+$'), '');
    if (base.startsWith('https://')) {
      return '${base.replaceFirst('https://', 'wss://')}/api/websocket';
    }
    if (base.startsWith('http://')) {
      return '${base.replaceFirst('http://', 'ws://')}/api/websocket';
    }
    return '$base/api/websocket';
  }

  Future<void> connect(String haUrl, String token) async {
    if (_connected) return;

    final wsUrl = _toWsUrl(haUrl);
    final authCompleter = Completer<void>();

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _channel!.stream.listen(
      (raw) {
        Map<String, dynamic> msg;
        try {
          msg = jsonDecode(raw as String) as Map<String, dynamic>;
        } catch (_) {
          return;
        }

        final type = msg['type'] as String?;

        if (type == 'auth_required') {
          _channel!.sink.add(jsonEncode({'type': 'auth', 'access_token': token}));
          return;
        }

        if (type == 'auth_ok') {
          _connected = true;
          if (!authCompleter.isCompleted) authCompleter.complete();
          return;
        }

        if (type == 'auth_invalid') {
          final err = Exception('HA auth_invalid: ${msg['message']}');
          if (!authCompleter.isCompleted) authCompleter.completeError(err);
          return;
        }

        if (type == 'result') {
          final id = msg['id'] as int?;
          if (id == null) return;
          final completer = _pending.remove(id);
          if (completer == null) return;
          final success = msg['success'] as bool? ?? false;
          if (success) {
            completer.complete(msg['result']);
          } else {
            final errMsg = (msg['error'] as Map?)?['message'] ?? 'HA request failed';
            completer.completeError(Exception(errMsg));
          }
          return;
        }

        if (type == 'event') {
          final id = msg['id'] as int?;
          if (id == null) return;
          final handler = _eventHandlers[id];
          if (handler != null) {
            final event = msg['event'] as Map<String, dynamic>?;
            if (event != null) handler(event);
          }
          return;
        }
      },
      onError: (e) {
        _connected = false;
        if (!authCompleter.isCompleted) authCompleter.completeError(e);
        _rejectPending(Exception('HA WebSocket error: $e'));
      },
      onDone: () {
        _connected = false;
        if (!authCompleter.isCompleted) {
          authCompleter.completeError(Exception('HA WebSocket closed before auth'));
        }
        _rejectPending(Exception('HA WebSocket closed'));
      },
    );

    await authCompleter.future;
  }

  void close() {
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _rejectPending(Exception('HA WebSocket closed'));
  }

  void _rejectPending(Exception e) {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(e);
    }
    _pending.clear();
    _eventHandlers.clear();
  }

  Future<T> _send<T>(Map<String, dynamic> payload) {
    if (_channel == null || !_connected) {
      return Future.error(Exception('HA WebSocket not connected'));
    }
    final id = _nextId++;
    final completer = Completer<T>();
    _pending[id] = completer as Completer<dynamic>;
    _channel!.sink.add(jsonEncode({'id': id, ...payload}));
    return completer.future;
  }

  Future<List<dynamic>> getStates() async {
    final result = await _send<dynamic>({'type': 'get_states'});
    return result as List<dynamic>;
  }

  Future<void> callService(String domain, String service, Map<String, dynamic> serviceData) async {
    await _send<dynamic>({
      'type': 'call_service',
      'domain': domain,
      'service': service,
      'service_data': serviceData,
    });
  }

  Future<int> subscribeStateChanged(StateChangedHandler handler) async {
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _eventHandlers[id] = (event) {
      final data = event['data'] as Map<String, dynamic>?;
      if (data == null) return;
      handler(
        entityId: data['entity_id'] as String? ?? '',
        newState: data['new_state'] as Map<String, dynamic>?,
        oldState: data['old_state'] as Map<String, dynamic>?,
      );
    };
    _channel!.sink.add(jsonEncode({'id': id, 'type': 'subscribe_events', 'event_type': 'state_changed'}));
    await completer.future;
    return id;
  }
}
