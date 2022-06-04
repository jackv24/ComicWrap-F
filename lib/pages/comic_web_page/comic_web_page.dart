import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/constants.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/download.dart';
import 'package:comicwrap_f/utils/error.dart';
import 'package:comicwrap_f/utils/settings.dart';
import 'package:comicwrap_f/widgets/more_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rxdart/subjects.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String interstitialAdId = String.fromEnvironment(
  'AD_ID_COMIC_WEB_PAGE_INTERSTITIAL',
  // Default is the Admob Interstitial Video Ad test ID
  defaultValue: 'ca-app-pub-3940256099942544/8691691433',
);

class ComicWebPage extends ConsumerStatefulWidget {
  final String comicId;
  final String initialPageId;

  const ComicWebPage(
      {required this.comicId, required this.initialPageId, Key? key})
      : super(key: key);

  @override
  _ComicWebPageState createState() => _ComicWebPageState();
}

class _ComicWebPageState extends ConsumerState<ComicWebPage> {
  DocumentSnapshot<SharedComicPageModel>? _newPage;
  DocumentSnapshot<SharedComicPageModel>? _newValidPage;
  DocumentSnapshot<SharedComicPageModel>? _currentPage;

  late String _rootUrl;
  final Completer<WebViewController> _webViewController =
      Completer<WebViewController>();

  late final BehaviorSubject<int> _progressSubject;

  InterstitialAd? _queuedInterstitialAd;

  @override
  void initState() {
    super.initState();

    // Enable hybrid composition on Android
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    // Construct url from comic scrape URL and page ID
    ref.read(sharedComicFamily(widget.comicId).future).then((sharedComic) {
      if (sharedComic == null) return;

      String scrapeUrl = sharedComic.scrapeUrl;
      if (!scrapeUrl.endsWith('/')) scrapeUrl += '/';
      _rootUrl = scrapeUrl;

      _navigateToPageId(widget.initialPageId, wasViaClick: false);
    });

    _progressSubject = BehaviorSubject.seeded(0);

    // Load ad immediately so it's ready when we need it
    _loadInterstitialAd().then((value) {
      _queuedInterstitialAd = value;
    });
  }

  @override
  void dispose() {
    _progressSubject.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final pageData = _newPage?.data();
    final pageTitle = pageData?.text ?? '';

    return Consumer(
      builder: (context, ref, child) {
        final appBarColor = ref.watch(appBarColorProvider(AppBarColorParams(
          comicId: widget.comicId,
          brightness: Theme.of(context).brightness,
        )));

        return Scaffold(
          // Hide single while pixel around webview
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: Text(pageTitle),
            backgroundColor: appBarColor,
            actions: [
              FutureBuilder<WebViewController>(
                future: _webViewController.future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Icon(Icons.more);
                  }

                  final controller = snapshot.data!;

                  return MoreActionButton(actions: [
                    FunctionListItem(
                      child: ListTile(
                        title: Text(loc.refresh),
                        trailing: const Icon(Icons.refresh),
                      ),
                      onSelected: (context) async {
                        await controller.reload();
                      },
                    ),
                    FunctionListItem(
                      child: ListTile(
                        title: Text(loc.webOpenBrowser),
                        trailing: const Icon(Icons.open_in_browser),
                      ),
                      onSelected: (context) async {
                        final url = await snapshot.data!.currentUrl();
                        await _tryLaunchUrl(url);
                      },
                    ),
                    FunctionListItem(
                      child: ListTile(
                        title: Text(loc.webToggleNavBar),
                        trailing: Consumer(builder: (context, ref, child) {
                          final value = ref
                              .watch(comicNavBarToggleProvider(widget.comicId));
                          return Icon(value
                              ? Icons.toggle_on
                              : Icons.toggle_off_outlined);
                        }),
                      ),
                      onSelected: (context) async {
                        final notifier = ref.read(
                            comicNavBarToggleProvider(widget.comicId).notifier);
                        final value =
                            ref.read(comicNavBarToggleProvider(widget.comicId));
                        notifier.setValue(!value);
                      },
                    ),
                  ]);
                },
              ),
            ],
          ),
          // Optionally show navigation bar
          bottomNavigationBar: Consumer(builder: (context, ref, child) {
            final value = ref.watch(comicNavBarToggleProvider(widget.comicId));

            // Can't return null here, so return empty widget
            if (!value) return const SizedBox.shrink();

            return _NavigationBar(
              comicId: widget.comicId,
              onNext: _newPage != null ? () => _goToNextPage(_newPage!) : null,
              onPrevious:
                  _newPage != null ? () => _goToPreviousPage(_newPage!) : null,
              onFirst: () => _goToFirstPage(context),
              onLast: () => _goToLastPage(context),
            );
          }),
          body: child,
        );
      },
      child: Stack(
        children: [
          // WebView wrapper
          Consumer(
            builder: (context, ref, child) {
              return WillPopScope(
                onWillPop: () async {
                  final userComicAsync =
                      ref.read(userComicFamily(widget.comicId));
                  final userComicSnapshot = userComicAsync.when(
                    data: (data) => data,
                    loading: () => null,
                    error: (err, stack) {
                      debugPrintStack(label: err.toString(), stackTrace: stack);
                      return null;
                    },
                  );

                  // Just pop if we couldn't get a ref to the user comic
                  if (userComicSnapshot == null) return true;

                  EasyLoading.show();
                  List<Future> futures = [];

                  // Wait for queued ad to show before popping screen
                  futures.add(_showInterstitialAd(_queuedInterstitialAd));

                  // Update read status when exiting, to avoid many doc updates while binge-reading
                  futures.add(_updateReadStatus(userComicSnapshot));

                  await Future.wait(futures);
                  EasyLoading.dismiss();

                  // Pop with value of current page
                  Navigator.of(context).pop(_newValidPage);

                  // We manually handle popping above
                  return false;
                },
                child: child!,
              );
            },
            // Webview child doesn't need to rebuild with parent Consumer
            child: Consumer(
              builder: (context, ref, child) {
                final userComicDocAsync =
                    ref.watch(userComicFamily(widget.comicId));
                final userComicDoc = userComicDocAsync.when(
                  data: (data) => data,
                  loading: () => null,
                  error: (error, stack) => null,
                );

                return WebView(
                  javascriptMode: JavascriptMode.unrestricted,
                  zoomEnabled: true,
                  onWebViewCreated: (webViewController) {
                    _webViewController.complete(webViewController);
                  },
                  navigationDelegate: (request) async {
                    // Fix some cases where WebView auto-navigates to some weird URL
                    if (request.url.startsWith('blob')) {
                      return NavigationDecision.prevent;
                    }

                    // Ignore iframes
                    if (!request.isForMainFrame) {
                      return NavigationDecision.navigate;
                    }

                    final rootHost = Uri.parse(_rootUrl).host;
                    final toHost = Uri.parse(request.url).host;

                    // Allow navigation within same website
                    // (check both in case one has www. and one doesn't)
                    if (rootHost.endsWith(toHost) ||
                        toHost.endsWith(rootHost)) {
                      _pageNavigatedViaClick();

                      return NavigationDecision.navigate;
                    }

                    // Launch external browser for external URLs
                    await _tryLaunchUrl(request.url);
                    return NavigationDecision.prevent;
                  },
                  onPageStarted: (pageUrl) {
                    print('onPageStarted URL: $pageUrl');

                    final pageId = pageUrl.split('/').skip(3).join(' ');
                    if (_newPage != null && pageId == _newPage!.id) {
                      // Don't trigger rebuild if we haven't changed page
                      print('Already on page: $pageId');
                      return;
                    } else {
                      print('Navigating to page: $pageId');
                      setState(() {
                        _newPage = null;
                      });
                    }

                    if (userComicDoc == null) return;

                    final pageRef = ref.read(sharedComicPageRefFamily(
                        SharedComicPageInfo(
                            comicId: widget.comicId, pageId: pageId)));

                    // Get data for the new page (don't wait)
                    pageRef?.get().then((value) {
                      if (!value.exists) {
                        print('Page does not exist: $pageId');
                        return;
                      }

                      // Update page display
                      setState(() {
                        _newPage = value;
                        _newValidPage = value;
                        print('Got data for page: $pageId');
                      });

                      // Don't need to wait for this, just let it happen whenever
                      _markPageRead(context, userComicDoc, value);
                    });
                  },
                  onProgress: (progress) => _progressSubject.add(progress),
                );
              },
            ),
          ),
          // Loading progress bar
          StreamBuilder<int>(
            stream: _progressSubject.stream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? 0;
              // Loading indicator only visible while still loading
              return Visibility(
                visible: value < 100,
                child: LinearProgressIndicator(
                  value: value / 100.0,
                  minHeight: 6.0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _markPageRead(
      BuildContext context,
      DocumentSnapshot<UserComicModel> userComic,
      DocumentSnapshot<SharedComicPageModel> sharedComicPage) async {
    // Try and get existing current page to compare scrape time
    if (_currentPage == null) {
      final currentPageId = userComic.data()!.currentPageId;
      if (currentPageId != null) {
        final pageRef = ref.read(sharedComicPageRefFamily(SharedComicPageInfo(
            comicId: widget.comicId, pageId: currentPageId)));

        _currentPage = await pageRef?.get();
      }
    }

    final docScrapeTime = sharedComicPage.data()!.scrapeTime;
    final currentPageScrapeTime = _currentPage?.data()!.scrapeTime;

    // Only record as current if doc page has been scraped
    if (docScrapeTime != null) {
      // If we don't have a current page then just make this the current
      if (_currentPage == null) {
        _currentPage = sharedComicPage;
      } else {
        // Otherwise make this the current if it's newer than the previous
        if (currentPageScrapeTime != null &&
            currentPageScrapeTime.compareTo(docScrapeTime) < 0) {
          _currentPage = sharedComicPage;
          print('_currentPage is now ${_currentPage!.id}');
        }
      }
    }
  }

  Future<void> _tryLaunchUrl(String? url) async {
    if (url != null && await canLaunch(url)) {
      await launch(url);
    } else {
      final loc = AppLocalizations.of(context);
      final displayUrl = url ?? 'null';
      await showErrorDialog(context, loc.webErrorUrl(displayUrl));
    }
  }

  Future<void> _updateReadStatus(
      DocumentSnapshot<UserComicModel?> userComicSnapshot) async {
    // Update read stats when exiting, to avoid many doc updates while binge-reading
    if (_currentPage != null) {
      var newFromPageId = userComicSnapshot.data()?.newFromPageId;
      if (newFromPageId == null) {
        // If there is no "new from page" just set it to the last page
        final lastPage =
            await ref.read(newestPageFamily(widget.comicId).future);
        newFromPageId = lastPage?.id;
      } else {
        final newFromPageRef = ref.read(sharedComicPageRefFamily(
            SharedComicPageInfo(
                comicId: widget.comicId, pageId: newFromPageId)));

        // If reading into the new pages, then set them as not new
        final newFromPage = await newFromPageRef?.get();
        final newScrapeTime = newFromPage?.data()?.scrapeTime;
        final currentScrapeTime = _currentPage!.data()?.scrapeTime;

        // Can only compare scrape times if both pages have them
        if (newScrapeTime != null &&
            currentScrapeTime != null &&
            currentScrapeTime.compareTo(newScrapeTime) > 0) {
          newFromPageId = _currentPage!.id;
        }
      }

      await userComicSnapshot.reference.update({
        'lastReadTime': Timestamp.now(),
        'currentPageId': _currentPage!.id,
        'newFromPageId': newFromPageId,
      });
    } else {
      // Don't set currentPage reference if it's null
      await userComicSnapshot.reference.update({
        'lastReadTime': Timestamp.now(),
      });
    }
  }

  Future<void> _navigateToPageId(String pageId,
      {required bool wasViaClick}) async {
    final pagePath = pageId.trim().replaceAll(' ', '/');

    // Wait for webview controller to be initialised
    final controller = await _webViewController.future;
    controller.loadUrl(_rootUrl + pagePath);

    if (wasViaClick) _pageNavigatedViaClick();
  }

  Future<void> _goToFirstPage(BuildContext context) async {
    final page = await ref.read(endPageFamily(SharedComicPagesQueryInfo(
      comicId: widget.comicId,
      descending: false,
    )).future);

    if (page == null) return;

    _navigateToPageId(page.id, wasViaClick: true);
  }

  Future<void> _goToLastPage(BuildContext context) async {
    final page = await ref.read(endPageFamily(SharedComicPagesQueryInfo(
      comicId: widget.comicId,
      descending: true,
    )).future);

    if (page == null) return;

    _navigateToPageId(page.id, wasViaClick: true);
  }

  Future<void> _goToQueriedPage({
    required Query<SharedComicPageModel> Function(Query<SharedComicPageModel>)
        getSubQuery,
    required bool descending,
  }) async {
    if (_newPage == null) return;

    final pagesQuery =
        ref.read(sharedComicPagesQueryFamily(SharedComicPagesQueryInfo(
      comicId: widget.comicId,
      descending: descending,
    )));

    if (pagesQuery == null) return;

    // Get pages below bottom
    final snapshot = await getSubQuery(pagesQuery).get();

    if (snapshot.docs.isEmpty) return;

    _navigateToPageId(snapshot.docs[0].id, wasViaClick: true);
  }

  Future<void> _goToNextPage(DocumentSnapshot<SharedComicPageModel> fromPage) {
    return _goToQueriedPage(
      getSubQuery: (rootQuery) =>
          rootQuery.startAfterDocument(fromPage).limit(1),
      descending: false,
    );
  }

  Future<void> _goToPreviousPage(
      DocumentSnapshot<SharedComicPageModel> fromPage) {
    return _goToQueriedPage(
      getSubQuery: (rootQuery) =>
          rootQuery.startAfterDocument(fromPage).limit(1),
      descending: true,
    );
  }

  void _pageNavigatedViaClick() {
    // (maybe) show ad on navigation to new page
    // (don't await, so page can load behind ad)
    _showInterstitialAd(_queuedInterstitialAd)
        // After ad has been shown, queue up another
        .then((value) => _loadInterstitialAd())
        .then((value) => _queuedInterstitialAd = value);
  }

  Future<InterstitialAd?> _loadInterstitialAd() async {
    // Handle completion in ad callbacks since load method doesn't return ad
    final completer = Completer<InterstitialAd?>();

    // Try load ad (may not load due to limits defined in AdMob console)
    await InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('InterstitialAd loaded: $ad');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  Future<void> _showInterstitialAd(InterstitialAd? ad) async {
    if (ad == null) return;

    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('Ad dismissed: $ad');
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('$ad failed to show fullscreen content: $error');
        completer.complete();
      },
    );

    // Ad is preloaded so add a short delay to make it's appearance less jarring
    await Future.delayed(const Duration(milliseconds: 100));
    await ad.show();

    return completer.future;
  }
}

class _NavigationBar extends ConsumerWidget {
  final String comicId;
  final void Function()? onPrevious;
  final void Function()? onNext;
  final void Function()? onFirst;
  final void Function()? onLast;

  const _NavigationBar({
    required this.comicId,
    this.onPrevious,
    this.onNext,
    this.onFirst,
    this.onLast,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarColor = ref.watch(appBarColorProvider(AppBarColorParams(
      comicId: comicId,
      brightness: Theme.of(context).brightness,
    )));

    return Material(
      color: appBarColor,
      child: LayoutBuilder(builder: (context, constraints) {
        final buttonColor = Theme.of(context).primaryIconTheme.color;

        final buttons = Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: onFirst,
              color: buttonColor,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onPrevious,
              color: buttonColor,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: onNext,
              color: buttonColor,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed: onLast,
              color: buttonColor,
            ),
          ],
        );

        final width = constraints.maxWidth;
        if (width > wideScreenThreshold) {
          final totalPadding = width - wideScreenThreshold;
          return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: (totalPadding / 2) + wideScreenExtraPadding),
            child: buttons,
          );
        } else {
          return buttons;
        }
      }),
    );
  }
}
