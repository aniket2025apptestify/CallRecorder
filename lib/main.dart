import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/recording_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/permission_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CallRecorderApp());
}

class CallRecorderApp extends StatelessWidget {
  const CallRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordingProvider(),
      child: MaterialApp(
        title: 'Call Recorder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          primaryColor: const Color(0xFFE94560),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE94560),
            secondary: Color(0xFF533483),
            surface: Color(0xFF1A1A2E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
          ),
          fontFamily: 'Roboto',
        ),
        home: const PermissionWrapper(),
        routes: {
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _permissionsGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionService.areAllPermissionsGranted();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
        _checking = false;
      });
    }

    if (!granted) {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionService.requestAllPermissions();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE94560)),
        ),
      );
    }

    if (!_permissionsGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE94560), Color(0xFF533483)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Permissions Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Call Recorder needs phone, microphone, and storage permissions to record and save your calls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Grant Permissions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}
