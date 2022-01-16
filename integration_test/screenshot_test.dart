import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/main.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/comic_page/comic_page.dart';
import 'package:comicwrap_f/utils/appwrite.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/download.dart';
import 'package:comicwrap_f/utils/settings.dart';
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
      await _pumpPromoMock(tester, ThemeMode.light);
      await _takeScreenshot(binding, tester, 'promo');
    });

    testWidgets('1_comicPage', (tester) async {
      final tooltip = await _pumpPromoMock(tester, ThemeMode.light);

      await tester.pumpAndSettle();
      final finder = find.byTooltip(tooltip);
      await tester.tap(finder);

      await _takeScreenshot(binding, tester, 'promo');
    });

    // TODO: 2_comicWebPage

    testWidgets('3_libraryScreenDark', (tester) async {
      await _pumpPromoMock(tester, ThemeMode.dark);
      await _takeScreenshot(binding, tester, 'promo');
    });
  });

  _runAppearanceTests(binding, ThemeMode.light);
  _runAppearanceTests(binding, ThemeMode.dark);
}

void _runAppearanceTests(
  IntegrationTestWidgetsFlutterBinding binding,
  ThemeMode themeMode,
) {
  final groupName = 'test_$themeMode';
  group(groupName, () {
    testWidgets('loginScreen', (tester) async {
      await tester.pumpWidget(_getCleanState(
        child: const MyApp(),
        themeMode: themeMode,
        extraOverrides: [
          userChangesProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      ));

      await _takeScreenshot(binding, tester, groupName);
    });

    testWidgets('emailSignUpScreen', (tester) async {
      await tester.pumpWidget(_getCleanState(
        child: const MyApp(),
        themeMode: themeMode,
        extraOverrides: [
          userChangesProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      ));

      await tester.pumpAndSettle();
      final finder = find.widgetWithText(TextButton, 'Sign Up with Email');
      await tester.tap(finder);

      await _takeScreenshot(binding, tester, groupName);
    });

    testWidgets('emailVerifyScreen', (tester) async {
      final user = MockUser();
      when(user.email).thenReturn('test@test.com');
      when(user.emailVerified).thenReturn(false);

      await tester.pumpWidget(_getCleanState(
        child: const MyApp(),
        themeMode: themeMode,
        extraOverrides: [
          userChangesProvider.overrideWithValue(AsyncValue.data(user)),
        ],
      ));

      await _takeScreenshot(binding, tester, groupName);
    });

    testWidgets('libraryScreen', (tester) async {
      final user = MockUser();
      when(user.emailVerified).thenReturn(true);

      await tester.pumpWidget(_getCleanState(
        child: const MyApp(),
        themeMode: themeMode,
        extraOverrides: [
          userChangesProvider.overrideWithValue(AsyncValue.data(user)),
          userComicsListProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      ));

      await _takeScreenshot(binding, tester, groupName);
    });

    testWidgets('settingsScreen', (tester) async {
      final user = MockUser();
      when(user.emailVerified).thenReturn(true);

      await tester.pumpWidget(_getCleanState(
        child: const MyApp(),
        themeMode: themeMode,
        extraOverrides: [
          userChangesProvider.overrideWithValue(AsyncValue.data(user)),
          userComicsListProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      ));

      await tester.pumpAndSettle();
      final finder = find.widgetWithIcon(IconButton, Icons.settings_rounded);
      await tester.tap(finder);

      await _takeScreenshot(binding, tester, groupName);
    });
  });
}

Widget _getCleanState({
  required Widget child,
  required ThemeMode themeMode,
  List<Override>? extraOverrides,
}) {
  WidgetsApp.debugAllowBannerOverride = false;

  return ProviderScope(
    overrides: [
      // Break firebaseProvider to force all firebase connections to be mocked
      clientProvider.overrideWithValue(AsyncValue.error('Not Implemented')),
      themeModeProvider
          .overrideWithValue(ThemeSettingNotifier(null, themeMode)),
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
  } //imageCacheManagerProvider.overrideWithValue(value),

  await tester.pumpAndSettle();
  await binding.takeScreenshot('$subFolder/${tester.testDescription}');
}

Future<String> _pumpPromoMock(WidgetTester tester, ThemeMode themeMode) async {
  final user = MockUser();
  when(user.emailVerified).thenReturn(true);

  final comics = [
    _generateMockComic(
      name: 'Tim & Jim: Adventure Bros',
      age: const Duration(hours: 3),
      newFromPage: 1,
      currentPage: 5,
      coverImageFile: 'integration_test/assets/comic_cover_bros.png',
    ),
    _generateMockComic(
      name: 'Fight!',
      age: const Duration(days: 5),
      currentPage: 2,
      coverImageFile: 'integration_test/assets/comic_cover_fight.png',
    ),
    _generateMockComic(
      name: 'Summer Time',
      age: const Duration(days: 12),
      coverImageFile: 'integration_test/assets/comic_cover_summer.png',
    ),
    _generateMockComic(
      name: 'Cool Shirts and Black Caps',
      age: const Duration(days: 15),
      coverImageFile: 'integration_test/assets/comic_cover_shirt.png',
    ),
  ];

  final List<Override> comicOverrides = [];
  final List<AssetImage?> coverImageProviders = [];
  for (final comic in comics) {
    final userDoc = comic.userDoc;
    final id = userDoc.id;
    final pages = comic.pages;
    final coverImageUrl = comic.sharedComic.coverImageUrl;
    final coverImageFile = comic.coverImageFile;

    final coverImageProvider = coverImageUrl != null && coverImageFile != null
        ? AssetImage(coverImageFile)
        : null;
    coverImageProviders.add(coverImageProvider);

    comicOverrides.addAll([
      userComicFamily(id).overrideWithValue(AsyncValue.data(userDoc)),
      sharedComicFamily(id)
          .overrideWithValue(AsyncValue.data(comic.sharedComic)),
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
      if (coverImageProvider != null)
        downloadImageFamily(coverImageUrl!).overrideWithValue(
            AsyncValue.data(ImageResponse(coverImageProvider, coverImageUrl))),
    ]);
  }

  const app = MyApp();
  await tester.pumpWidget(_getCleanState(
    child: app,
    themeMode: themeMode,
    extraOverrides: [
      userChangesProvider.overrideWithValue(AsyncValue.data(user)),
      userComicsListProvider.overrideWithValue(
          AsyncValue.data(comics.map((e) => e.userDoc).toList())),
      ...comicOverrides,
    ],
  ));
  await tester.pumpAndSettle();

  // Wait for all cover images to be pre-cached
  final BuildContext appContext = tester.element(find.byWidget(app));
  for (final provider in coverImageProviders) {
    if (provider != null) await precacheImage(provider, appContext);
  }
  await tester.pumpAndSettle();

  // Return name of first comic to be found by tooltip to tap
  return comics.first.sharedComic.name!;
}

class _MockComicData {
  final MockDocumentSnapshot<UserComicModel> userDoc;
  final SharedComicModel sharedComic;
  final String? coverImageFile;
  final List<MockDocumentSnapshot<SharedComicPageModel>> pages;
  final int? newFromPage;
  final int? currentPage;

  _MockComicData(
      {required this.userDoc,
      required this.sharedComic,
      this.coverImageFile,
      required this.pages,
      this.newFromPage,
      this.currentPage});
}

_MockComicData _generateMockComic(
    {required String name,
    required Duration age,
    int? newFromPage,
    int? currentPage,
    String? coverImageFile}) {
  final userDoc = MockDocumentSnapshot<UserComicModel>();
  when(userDoc.id).thenReturn(name);
  when(userDoc.data())
      .thenReturn(UserComicModel(lastReadTime: DateTime.now().subtract(age)));

  final pages = _generateMockPages();

  return _MockComicData(
    userDoc: userDoc,
    sharedComic: SharedComicModel(
        scrapeUrl: name,
        name: name,
        coverImageUrl:
            coverImageFile != null ? 'http://$coverImageFile' : null),
    coverImageFile: coverImageFile,
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
        scrapeTime: DateTime.now().subtract(Duration(days: pageCount - i))));
    list.add(page);
  }
  return list;
}
