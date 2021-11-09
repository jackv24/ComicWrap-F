import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/main.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/comic_page/comic_page.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('promo', () {
    testWidgets('0_libraryScreen', (tester) async {
      await _pumpPromoMock(tester);
      await _takeScreenshot(binding, tester, 'promo');
    });

    testWidgets('1_comicPage', (tester) async {
      final tooltip = await _pumpPromoMock(tester);

      await tester.pumpAndSettle();
      final finder = find.byTooltip(tooltip);
      await tester.tap(finder);

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
  // Android special handling
  if (Platform.isAndroid) {
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
  }

  await tester.pumpAndSettle();
  await binding.takeScreenshot('$subFolder/${tester.testDescription}');
}

Future<String> _pumpPromoMock(WidgetTester tester) async {
  final user = MockUser();
  when(user.emailVerified).thenReturn(true);

  final comics = [
    _generateMockComic(
      name: 'Tim & Jim: Adventure Bros',
      age: const Duration(hours: 3),
      newFromPage: 1,
      currentPage: 5,
    ),
    _generateMockComic(
      name: 'Fight!',
      age: const Duration(days: 5),
      currentPage: 2,
    ),
    _generateMockComic(
      name: 'Summer Time',
      age: const Duration(days: 12),
    ),
    _generateMockComic(
      name: 'Cool Shirts and Black Caps',
      age: const Duration(days: 15),
    ),
  ];

  final List<Override> comicOverrides = [];
  for (final comic in comics) {
    final userDoc = comic.userDoc;
    final id = userDoc.id;
    final pages = comic.pages;
    comicOverrides.addAll([
      userComicFamily(id).overrideWithValue(AsyncValue.data(userDoc)),
      sharedComicFamily(id).overrideWithValue(AsyncValue.data(
          SharedComicModel(scrapeUrl: id, name: comic.sharedComic.name))),
      pageListOverrideProvider(id).overrideWithValue(comic.pages),
      newestPageFamily(id).overrideWithValue(AsyncValue.data(pages.first)),
      newFromPageFamily(id).overrideWithValue(AsyncValue.data(
          comic.newFromPage != null ? pages[comic.newFromPage!] : null)),
      currentPageFamily(id).overrideWithValue(AsyncValue.data(
          comic.currentPage != null ? pages[comic.currentPage!] : null)),
      endPageFamily(SharedComicPagesQueryInfo(comicId: id, descending: false))
          .overrideWithValue(AsyncValue.data(pages.first)),
      endPageFamily(SharedComicPagesQueryInfo(comicId: id, descending: true))
          .overrideWithValue(AsyncValue.data(pages.last)),
    ]);
  }

  await tester.pumpWidget(_getCleanState(
    child: const MyApp(),
    extraOverrides: [
      userChangesProvider.overrideWithValue(AsyncValue.data(user)),
      userComicsListProvider.overrideWithValue(
          AsyncValue.data(comics.map((e) => e.userDoc).toList())),
      ...comicOverrides,
      //imageCacheManagerProvider.overrideWithValue(value),
    ],
  ));

  // Return name of first comic to be found by tooltip to tap
  return comics.first.sharedComic.name!;
}

class _MockComicData {
  final MockDocumentSnapshot<UserComicModel> userDoc;
  final SharedComicModel sharedComic;
  final List<MockDocumentSnapshot<SharedComicPageModel>> pages;
  final int? newFromPage;
  final int? currentPage;

  _MockComicData(
      {required this.userDoc,
      required this.sharedComic,
      required this.pages,
      this.newFromPage,
      this.currentPage});
}

_MockComicData _generateMockComic(
    {required String name,
    required Duration age,
    int? newFromPage,
    int? currentPage}) {
  final userDoc = MockDocumentSnapshot<UserComicModel>();
  when(userDoc.id).thenReturn(name);
  when(userDoc.data()).thenReturn(UserComicModel(
      lastReadTime: Timestamp.fromDate(DateTime.now().subtract(age))));

  final pages = _generateMockPages();

  return _MockComicData(
    userDoc: userDoc,
    sharedComic: SharedComicModel(scrapeUrl: name, name: name),
    pages: pages,
    newFromPage: newFromPage,
    currentPage: currentPage,
  );
}

List<MockDocumentSnapshot<SharedComicPageModel>> _generateMockPages() {
  const pageCount = 50;
  final List<MockDocumentSnapshot<SharedComicPageModel>> list = [];
  for (int i = pageCount; i > 0; i--) {
    final page = MockDocumentSnapshot<SharedComicPageModel>();
    when(page.id).thenReturn('comic page$i');
    when(page.data()).thenReturn(SharedComicPageModel(
        text: 'Page $i',
        scrapeTime: Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: pageCount - i)))));
    list.add(page);
  }
  return list;
}
