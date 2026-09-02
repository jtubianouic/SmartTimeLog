import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/smart_time_log_api.dart';
import 'theme/app_theme.dart';
import 'providers/theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/geofence_clockin_screen.dart';
import 'screens/active_shift_screen.dart';
import 'screens/clockout_screen.dart';
import 'screens/ai_summary_screen.dart';
import 'screens/session_gate.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  final baseUrl = dotenv.env['BASE_URL'];
  if (baseUrl == null || baseUrl.isEmpty) {
    throw StateError('BASE_URL is missing from .env');
  }
  await SmartTimeLogApi.initialize(baseUrl: baseUrl);

  runApp(const MyApp());
}

final themeNotifier = ThemeNotifier();

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home = const SessionGate()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'SmartTimeLog',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: home,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/geofence': (context) => const GeofenceClockInScreen(),
            '/active-shift': (context) => const ActiveShiftScreen(),
            '/clockout': (context) => const ClockOutScreen(),
            '/summary': (context) => const AISummaryScreen(),
          },
        );
      },
    );
  }
}
