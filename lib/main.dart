import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/ha_runtime_config.dart';
import 'config/reload_ha_config.dart';
import 'config/ha_secrets.dart' as secrets;
import 'providers/device_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const OfficeControlApp());
}

class OfficeControlApp extends StatefulWidget {
  const OfficeControlApp({super.key});

  @override
  State<OfficeControlApp> createState() => _OfficeControlAppState();
}

class _OfficeControlAppState extends State<OfficeControlApp> {
  String? _haUrl;
  String? _haToken;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    reloadHaConfiguration = _load;
    _load();
  }

  @override
  void dispose() {
    reloadHaConfiguration = null;
    super.dispose();
  }

  Future<void> _load() async {
    // Static credentials are sourced from `lib/config/ha_secrets.dart`.
    // You can override them at build/run time with --dart-define=OFFICE_HA_URL / OFFICE_HA_TOKEN.
    var url = secrets.kHaBaseUrl.trim();
    var token = secrets.kHaToken.trim();

    final fromUrl = HaRuntimeConfig.officeHaUrl.trim();
    final fromToken = HaRuntimeConfig.officeHaToken.trim();

    if (fromUrl.isNotEmpty) url = normalizeHaBaseUrl(fromUrl);
    if (fromToken.isNotEmpty) token = fromToken;

    if (url.isEmpty) url = kDefaultHaBaseUrl;

    if (!mounted) return;
    setState(() {
      _haUrl = url;
      _haToken = token;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final configured = (_haUrl ?? '').isNotEmpty && (_haToken ?? '').isNotEmpty;

    return MaterialApp(
      title: 'OfficeControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
        ),
      ),
      home: configured
          ? ChangeNotifierProvider(
              key: ValueKey<String>('${_haUrl!}|${_haToken!}'),
              create: (_) => DeviceProvider(
                haUrl: _haUrl!,
                haToken: _haToken!,
              ),
              child: const MainScreen(),
            )
          : const _MissingConfigScreen(),
    );
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'OfficeControl',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Missing Home Assistant credentials.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 14),
                Text(
                  'Build/run with:\n'
                  '  --dart-define=OFFICE_HA_URL=...\n'
                  '  --dart-define=OFFICE_HA_TOKEN=...',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
