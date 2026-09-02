// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarttimelog/main.dart';
import 'package:smarttimelog/screens/active_shift_screen.dart';
import 'package:smarttimelog/screens/ai_summary_screen.dart';
import 'package:smarttimelog/screens/clockout_screen.dart';
import 'package:smarttimelog/screens/geofence_clockin_screen.dart';
import 'package:smarttimelog/screens/login_screen.dart';
import 'package:smarttimelog/services/session_storage.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';

void main() {
  final storage = _EmptySessionStorage();

  setUpAll(() async {
    await SmartTimeLogApi.initialize(
      baseUrl: 'https://example.com',
      sessionStorage: storage,
    );
  });

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

    expect(storage.clearCount, clearsBeforeLogout + 1);
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
}

class _EmptySessionStorage implements SessionStorage {
  int clearCount = 0;

  @override
  Future<void> deleteAll() async => clearCount++;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}
