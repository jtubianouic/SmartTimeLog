// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarttimelog/main.dart';
import 'package:smarttimelog/providers/theme_notifier.dart';
import 'package:smarttimelog/screens/active_shift_screen.dart';
import 'package:smarttimelog/screens/ai_summary_screen.dart';
import 'package:smarttimelog/screens/attendance_history_screen.dart';
import 'package:smarttimelog/screens/clockout_screen.dart';
import 'package:smarttimelog/screens/geofence_clockin_screen.dart';
import 'package:smarttimelog/screens/login_screen.dart';
import 'package:smarttimelog/services/session_storage.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';
import 'package:smarttimelog/widgets/onboarding_walkthrough.dart';

void main() {
  final storage = _EmptySessionStorage();

  setUpAll(() async {
    await SmartTimeLogApi.initialize(
      baseUrl: 'https://smarttimelog-admin.vercel.app',
      sessionStorage: storage,
    );
  });

  setUp(() => themeNotifier.setTheme(ThemeMode.light));

  testWidgets('Login screen supports light and dark themes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(home: LoginScreen()));

    expect(find.text('SmartTimeLog'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Enter your username and password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid persisted session routes to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('authenticated pages can log out', (WidgetTester tester) async {
    final clearsBeforeLogout = storage.clearCount;

    await tester.pumpWidget(const MyApp(home: GeofenceClockInScreen()));

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Log out'),
      ),
    );
    await tester.pumpAndSettle();

    expect(storage.clearCount, clearsBeforeLogout + 3);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Geofence clock-in'), findsNothing);
  });

  testWidgets('active break prevents clock-out', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        home: ActiveShiftScreen(initiallyOnBreak: true, hasTakenBreak: true),
      ),
    );

    final clockOut = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Clock out'),
    );
    expect(find.text('End break'), findsOneWidget);
    expect(clockOut.onPressed, isNull);
  });

  testWidgets('clock-out requires a completed break', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(home: ActiveShiftScreen()));

    final clockOut = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Clock out'),
    );
    expect(find.text('Take your break before clocking out'), findsOneWidget);
    expect(clockOut.onPressed, isNull);
  });

  testWidgets('taking a break requires confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(home: ActiveShiftScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Take break'));
    await tester.pump();

    expect(find.text('Start your break?'), findsOneWidget);
    expect(
      find.text('Your working time will pause and break time will start.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start break'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Start your break?'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Take break'), findsOneWidget);
  });

  testWidgets('ending a break requires confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        home: ActiveShiftScreen(initiallyOnBreak: true, hasTakenBreak: true),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'End break'));
    await tester.pump();

    expect(find.text('End your break?'), findsOneWidget);
    expect(
      find.text('Break time will stop and your working time will resume.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Keep break'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'End break'), findsWidgets);
  });

  testWidgets('completed break cannot be taken again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(home: ActiveShiftScreen(hasTakenBreak: true)),
    );

    final breakButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Break completed'),
    );
    final clockOut = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Clock out'),
    );
    expect(breakButton.onPressed, isNull);
    expect(clockOut.onPressed, isNotNull);
  });

  testWidgets('active shift displays attendance durations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        home: ActiveShiftScreen(
          hasTakenBreak: true,
          initialClockedInDurationSeconds: 3661,
          initialBreakDurationSeconds: 300,
        ),
      ),
    );

    expect(find.text('01:01:01'), findsOneWidget);
    expect(find.text('00:56:01'), findsOneWidget);
    expect(find.text('00:05:00'), findsOneWidget);
  });

  testWidgets('main workflow exposes theme and attendance history actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(home: ActiveShiftScreen(hasTakenBreak: true)),
    );

    expect(find.byTooltip('Dark Mode'), findsOneWidget);
    expect(find.byTooltip('Attendance history'), findsOneWidget);

    await tester.tap(find.byTooltip('Dark Mode'));
    await tester.pump();

    expect(find.byTooltip('Light Mode'), findsOneWidget);
  });

  testWidgets('clock-out displays actual session and no project selector', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        home: ClockOutScreen(
          initialClockInTime: DateTime(2026, 9, 2, 9),
          initialClockedInDurationSeconds: 3661,
          initialBreakDurationSeconds: 300,
        ),
      ),
    );

    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('01:01:01'), findsOneWidget);
    expect(find.text('00:05:00'), findsOneWidget);
    expect(find.text('00:56:01'), findsOneWidget);
    expect(find.text('Project/Client'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('AI summary displays real durations and generated text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        home: AISummaryScreen(
          summary: 'Completed the attendance dashboard.',
          employeeInput: 'Activities and notes: Dashboard work',
          clockedInDurationSeconds: 3661,
          breakDurationSeconds: 300,
        ),
      ),
    );

    expect(find.text('01:01:01'), findsOneWidget);
    expect(find.text('00:05:00'), findsOneWidget);
    expect(find.text('00:56:01'), findsOneWidget);
    expect(find.text('Completed the attendance dashboard.'), findsOneWidget);
  });

  testWidgets('onboarding introduces geofencing, shifts, and AI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OnboardingWalkthrough())),
    );

    expect(find.text('Clock in with geofencing'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Track shifts and breaks'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Create an AI work summary'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('attendance history displays timestamped break logs', (
    WidgetTester tester,
  ) async {
    final timelogs = [
      AttendanceTimelog(
        id: 2,
        employeeId: 42,
        type: AttendanceTimelogType.breakStart,
        timestamp: DateTime(2026, 9, 22, 12, 30),
        latitude: 7.0731,
        longitude: 125.6128,
      ),
      AttendanceTimelog(
        id: 1,
        employeeId: 42,
        type: AttendanceTimelogType.clockIn,
        timestamp: DateTime(2026, 9, 22, 9),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceHistoryScreen(loadTimelogs: () async => timelogs),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attendance history'), findsOneWidget);
    expect(find.text('Break started'), findsOneWidget);
    expect(find.text('Clocked in'), findsOneWidget);
    expect(find.text('Sep 22, 2026 at 12:30 PM'), findsOneWidget);
  });

  test('clock-in guard detects active shifts and breaks', () {
    AttendanceStatus status(AttendanceState state) => AttendanceStatus(
      date: DateTime(2026, 9, 22),
      state: state,
      clockedInDurationSeconds: 0,
      breakDurationSeconds: 0,
      currentBreakDurationSeconds: 0,
      latestTimelog: null,
    );

    expect(hasClockInStateConflict(status(AttendanceState.onBreak)), isTrue);
    expect(hasClockInStateConflict(status(AttendanceState.clockedIn)), isTrue);
    expect(
      hasClockInStateConflict(status(AttendanceState.notClockedIn)),
      isFalse,
    );
    expect(
      hasClockInStateConflict(status(AttendanceState.clockedOut)),
      isFalse,
    );
  });

  testWidgets('clock-in during a break requires confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ClockInStateConflictDialog(isOnBreak: true)),
      ),
    );

    expect(find.text('Break already active'), findsOneWidget);
    expect(
      find.textContaining('create an invalid attendance state'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Stay here'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Return to shift'),
      findsOneWidget,
    );
  });

  testWidgets('clock-in requires confirmation before proceeding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ClockInConfirmationDialog())),
    );

    expect(find.text('Clock in now?'), findsOneWidget);
    expect(
      find.text('Your current location and clock-in time will be recorded.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Clock in'), findsOneWidget);
  });
}

class _EmptySessionStorage implements SessionStorage {
  int clearCount = 0;

  @override
  Future<void> delete(String key) async => clearCount++;

  @override
  Future<void> deleteAll() async => clearCount += 3;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}
