import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/main.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
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

@GenerateMocks([User, DocumentSnapshot])
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding();

  group('promo', () {
    testWidgets('0_libraryScreen', (tester) async {
      await _pumpPromoMock(tester);
      await _takeScreenshot(binding, tester, 'promo');
    });
  });

  group('test', () {
    testWidgets('loginScreen', (tester) async {
      await tester.pumpWidget(_getCleanState(
        child: const MyApp(),
        extraOverrides: [
          userChangesProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      ));

      await _takeScreenshot(binding, tester, 'test');
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

      await _takeScreenshot(binding, tester, 'test');
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

      await _takeScreenshot(binding, tester, 'test');
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

      await _takeScreenshot(binding, tester, 'test');
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

      await _takeScreenshot(binding, tester, 'test');
    });
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

Future<void> _takeScreenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String subFolder) async {
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
  await binding
      .takeScreenshot('$subFolder/$platformName/${tester.testDescription}');
}

Future<void> _pumpPromoMock(WidgetTester tester) async {
  final user = MockUser();
  when(user.emailVerified).thenReturn(true);

  final userDoc1 = MockDocumentSnapshot<UserComicModel>();
  when(userDoc1.id).thenReturn('www.test1.com');
  when(userDoc1.data()).thenReturn(UserComicModel());
  final userDoc2 = MockDocumentSnapshot<UserComicModel>();
  when(userDoc2.id).thenReturn('www.test2.com');
  when(userDoc2.data()).thenReturn(UserComicModel());
  final docs = [userDoc1, userDoc2];

  await tester.pumpWidget(_getCleanState(
    child: const MyApp(),
    extraOverrides: [
      userChangesProvider.overrideWithValue(AsyncValue.data(user)),
      userComicsListProvider.overrideWithValue(AsyncValue.data(docs)),
      sharedComicFamily(userDoc1.id).overrideWithValue(AsyncValue.data(
          SharedComicModel(scrapeUrl: userDoc1.id, name: 'Test 1'))),
      sharedComicFamily(userDoc2.id)
          .overrideWithValue(AsyncValue.data(SharedComicModel(
        scrapeUrl: userDoc2.id,
        name: 'Test 2',
        isImporting: true,
      ))),
    ],
  ));
}
