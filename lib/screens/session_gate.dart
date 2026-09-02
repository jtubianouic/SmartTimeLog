import 'package:flutter/material.dart';

import '../services/smart_time_log_api.dart';
import 'active_shift_screen.dart';
import 'geofence_clockin_screen.dart';
import 'login_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  static bool _requiresLogin(ApiException error) =>
      error.statusCode == 401 || error.statusCode == 403;

  static Future<void> routeAuthenticatedSession(BuildContext context) async {
    final api = SmartTimeLogApi.instance;
    try {
      final status = await api.getAttendanceStatus();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => destinationFor(status)),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (!context.mounted) return;
      if (_requiresLogin(error)) {
        await api.clearSession();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      rethrow;
    }
  }

  static Widget destinationFor(AttendanceStatus status) {
    final api = SmartTimeLogApi.instance;
    return switch (status.state) {
      AttendanceState.clockedIn || AttendanceState.onBreak => ActiveShiftScreen(
        initiallyOnBreak: status.state == AttendanceState.onBreak,
        hasTakenBreak: status.hasTakenBreak,
        initialClockedInDurationSeconds: status.clockedInDurationSeconds,
        initialBreakDurationSeconds: status.breakDurationSeconds,
        initialCurrentBreakDurationSeconds: status.currentBreakDurationSeconds,
      ),
      AttendanceState.notClockedIn || AttendanceState.clockedOut =>
        GeofenceClockInScreen(headquarters: api.currentEmployee?.headquarters),
    };
  }

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final api = SmartTimeLogApi.instance;
    if (!api.hasSession) {
      _replace(const LoginScreen());
      return;
    }

    setState(() => _error = null);
    try {
      final status = await api.getAttendanceStatus();
      _replace(SessionGate.destinationFor(status));
    } on ApiException catch (error) {
      if (SessionGate._requiresLogin(error)) {
        await api.clearSession();
        _replace(const LoginScreen());
      } else if (mounted) {
        setState(() => _error = error.message);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _error = 'Unable to restore your session. Please try again.',
        );
      }
    }
  }

  void _replace(Widget destination) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _resolve,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
