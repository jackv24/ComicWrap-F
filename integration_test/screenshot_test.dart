import 'dart:io';

import 'package:comicwrap_f/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding();

  testWidgets('loginScreen', (tester) async {
    // TODO: Mock ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    await _takeScreenshot(binding, tester);
  });

  testWidgets('emailSignUpScreen', (tester) async {
    // TODO: Mock ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    await tester.pumpAndSettle();
    final finder = find.widgetWithText(TextButton, 'Sign Up with Email');
    await tester.tap(finder);

    await _takeScreenshot(binding, tester);
  });
}

Future<void> _takeScreenshot(
    IntegrationTestWidgetsFlutterBinding binding, WidgetTester tester) async {
  // Special per-platform setup + name
  final String platformName;
  if (!kIsWeb) {
    await binding.convertFlutterSurfaceToImage();
    if (Platform.isAndroid) {
      platformName = 'android';
    } else if (Platform.isIOS) {
      platformName = 'ios';
    } else {
      platformName = 'unknown';
    }
  } else {
    platformName = 'web';
  }

  await tester.pumpAndSettle();
  await binding.takeScreenshot('$platformName-${tester.testDescription}');
}
