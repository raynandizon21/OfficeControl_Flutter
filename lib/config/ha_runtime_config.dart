// ---------------------------------------------------------------------------
// Optional compile-time credentials (never commit secrets — pass at run/build):
//
//   flutter run -d chrome --dart-define=OFFICE_HA_URL=http://host:8123 \
//     --dart-define=OFFICE_HA_TOKEN=YOUR_TOKEN
//
// Web / Edge supports the same flags.
// ---------------------------------------------------------------------------

const String kDefaultHaBaseUrl = 'http://iot3core21.ddns.net:8123';

class HaRuntimeConfig {
  HaRuntimeConfig._();

  static const String officeHaUrl =
      String.fromEnvironment('OFFICE_HA_URL', defaultValue: '');
  static const String officeHaToken =
      String.fromEnvironment('OFFICE_HA_TOKEN', defaultValue: '');
}

class HaStaticConfig {
  HaStaticConfig._();

  // Fallback values are in `ha_secrets.dart` (local-only, gitignored).
  static const String baseUrl = String.fromEnvironment('OFFICE_HA_STATIC_URL', defaultValue: '');
  static const String token = String.fromEnvironment('OFFICE_HA_STATIC_TOKEN', defaultValue: '');
}

String normalizeHaBaseUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return url;
  url = url.replaceAll(RegExp(r'/+$'), '');
  if (!url.contains('://')) {
    url = 'http://$url';
  }
  return url;
}
