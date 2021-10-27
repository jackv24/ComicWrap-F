import 'dart:io';

import 'package:comicwrap_f/main.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'screenshot_test.mocks.dart';

@GenerateMocks([User])
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding();

  testWidgets('loginScreen', (tester) async {
    await tester.pumpWidget(_getCleanState(
      child: const MyApp(),
      extraOverrides: [
        userChangesProvider.overrideWithValue(const AsyncValue.data(null)),
      ],
    ));

    await _takeScreenshot(binding, tester);
  });

  testWidgets('emailSignUpScreen', (tester) async {
    await tester.pumpWidget(_getCleanState(
      child: const MyApp(),
      extraOverrides: [
        userChangesProvider.overrideWithValue(const AsyncValue.data(null)),
      ],
    ));

    await tester.pumpAndSettle();
    final finder = find.widgetWithText(TextButton, 'Sign Up with Email');
    await tester.tap(finder);

    await _takeScreenshot(binding, tester);
  });

  testWidgets('emailVerifyScreen', (tester) async {
    final user = MockUser();
    when(user.email).thenReturn('test@test.com');
    when(user.emailVerified).thenReturn(false);

    await tester.pumpWidget(_getCleanState(
      child: const MyApp(),
      extraOverrides: [
        userChangesProvider.overrideWithValue(AsyncValue.data(user)),
      ],
    ));

    await _takeScreenshot(binding, tester);
  });

  testWidgets('libraryScreen', (tester) async {
    final user = MockUser();
    when(user.emailVerified).thenReturn(true);

    await tester.pumpWidget(_getCleanState(
      child: const MyApp(),
      extraOverrides: [
        userChangesProvider.overrideWithValue(AsyncValue.data(user)),
        userComicsListProvider.overrideWithValue(const AsyncValue.data(null)),
      ],
    ));

    await _takeScreenshot(binding, tester);
  });

  testWidgets('settingsScreen', (tester) async {
    final user = MockUser();
    when(user.emailVerified).thenReturn(true);

    await tester.pumpWidget(_getCleanState(
      child: const MyApp(),
      extraOverrides: [
        userChangesProvider.overrideWithValue(AsyncValue.data(user)),
        userComicsListProvider.overrideWithValue(const AsyncValue.data(null)),
      ],
    ));

    await tester.pumpAndSettle();
    final finder = find.widgetWithIcon(IconButton, Icons.settings_rounded);
    await tester.tap(finder);

    await _takeScreenshot(binding, tester);
  });
}

Widget _getCleanState({required Widget child, List<Override>? extraOverrides}) {
  return ProviderScope(
    overrides: [
      // Break firebaseProvider to force all firebase connections to be mocked
      firebaseProvider.overrideWithValue(AsyncValue.error('Not Implemented')),
      ...?extraOverrides,
    ],
    child: child,
  );
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
