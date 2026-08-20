import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'theme/app_theme.dart';
import 'providers/theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/geofence_clockin_screen.dart';
import 'screens/active_shift_screen.dart';
import 'screens/clockout_screen.dart';
import 'screens/ai_summary_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
final themeNotifier = ThemeNotifier();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ShadApp(
          title: 'SmartTimeLog',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightShadTheme(),
          darkTheme: AppTheme.darkShadTheme(),
          materialThemeBuilder: (context, theme) {
            return theme.brightness == Brightness.dark
                ? AppTheme.darkTheme()
                : AppTheme.lightTheme();
          },
          home: const LoginScreen(),
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
