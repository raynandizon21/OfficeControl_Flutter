import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/device_provider.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

// ---------------------------------------------------------------------------
// Default credentials (from .env.local). Can be overridden via Settings screen.
// ---------------------------------------------------------------------------
const _kDefaultHaUrl = 'http://192.168.110.200:8123';
const _kDefaultHaToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiI0Yjg2Yjk4OWM4Yzc0Y2U4YmZhZDUxZDdmYjMxNmEzNyIsImlhdCI6MTc3MDk3MDM0OSwiZXhwIjoyMDg2MzMwMzQ5fQ'
    '.w75Fv1K7a0uPF_MpktOoVo0rQhBNwFRu62w23Mprsw4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
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
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Falls back to the hardcoded office credentials if not yet overridden via settings.
      _haUrl = prefs.getString('ha_url') ?? _kDefaultHaUrl;
      _haToken = prefs.getString('ha_token') ?? _kDefaultHaToken;
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
              create: (_) => DeviceProvider(
                haUrl: _haUrl!,
                haToken: _haToken!,
              ),
              child: const MainScreen(),
            )
          : SettingsScreen(
              onConnected: () {
                _load();
              },
            ),
    );
  }
}
