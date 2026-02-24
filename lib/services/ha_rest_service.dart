import 'dart:convert';
import 'package:http/http.dart' as http;

class HaEntityState {
  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;

  HaEntityState({
    required this.entityId,
    required this.state,
    required this.attributes,
  });

  factory HaEntityState.fromJson(Map<String, dynamic> json) {
    return HaEntityState(
      entityId: json['entity_id'] as String,
      state: json['state'] as String,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class HaRestService {
  final String baseUrl;
  final String token;

  HaRestService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  String _url(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base$path';
  }

  Future<List<HaEntityState>> getAllStates() async {
    final res = await http.get(Uri.parse(_url('/api/states')), headers: _headers);
    if (res.statusCode != 200) throw Exception('HA getAllStates failed (${res.statusCode}): ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => HaEntityState.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> callService(String domain, String service, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(_url('/api/services/$domain/$service')),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HA callService $domain.$service failed (${res.statusCode}): ${res.body}');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool? coverStateToStatus(String state) {
    final s = state.toLowerCase();
    if (s == 'open' || s == 'opening') return true;
    if (s == 'closed' || s == 'closing') return false;
    return null;
  }

  static double? lightBrightness(Map<String, dynamic> attrs) {
    if (attrs['brightness_pct'] is num) {
      return (attrs['brightness_pct'] as num).toDouble().clamp(0, 100);
    }
    if (attrs['brightness'] is num) {
      return ((attrs['brightness'] as num).toDouble() / 255 * 100).clamp(0, 100);
    }
    return null;
  }
}
