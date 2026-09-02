// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarttimelog/main.dart';
import 'package:smarttimelog/screens/login_screen.dart';
import 'package:smarttimelog/services/session_storage.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';

void main() {
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
    await SmartTimeLogApi.initialize(
      baseUrl: 'https://example.com',
      sessionStorage: _EmptySessionStorage(),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Log In'), findsOneWidget);
  });
}

class _EmptySessionStorage implements SessionStorage {
  @override
  Future<void> deleteAll() async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}
