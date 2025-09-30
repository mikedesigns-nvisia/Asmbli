import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to pump widgets with necessary providers for testing
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: widget,
        ),
      ),
    ),
  );
}

/// Pump and settle with timeout to prevent hanging tests
Future<void> pumpAndSettleSafe(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await tester.pumpAndSettle(timeout);
  } catch (e) {
    // Timeout occurred - test should handle this
    rethrow;
  }
}

/// Pump with custom theme for design system testing
Future<void> pumpAppWithTheme(
  WidgetTester tester,
  Widget widget, {
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        themeMode: themeMode,
        home: Scaffold(
          body: widget,
        ),
      ),
    ),
  );
}