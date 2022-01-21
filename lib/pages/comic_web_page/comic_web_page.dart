import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/error.dart';
import 'package:comicwrap_f/widgets/more_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/subjects.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ComicWebPage extends StatefulWidget {
  final String comicId;
  final String initialPageId;

  const ComicWebPage(
      {required this.comicId, required this.initialPageId, Key? key})
      : super(key: key);

  @override
  _ComicWebPageState createState() => _ComicWebPageState();
}

class _ComicWebPageState extends State<ComicWebPage> {
  DocumentSnapshot<SharedComicPageModel>? _newPage;
  DocumentSnapshot<SharedComicPageModel>? _newValidPage;
  DocumentSnapshot<SharedComicPageModel>? _currentPage;

  late String rootUrl;
  final Completer<WebViewController> _webViewController =
      Completer<WebViewController>();

  late final BehaviorSubject<int> _progressSubject;

  @override
  void initState() {
    super.initState();

    // Enable hybrid composition on Android
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    // Construct url from comic scrape URL and page ID
    context.read(sharedComicFamily(widget.comicId).last).then((sharedComic) {
      if (sharedComic == null) return;

      String scrapeUrl = sharedComic.scrapeUrl;
      if (!scrapeUrl.endsWith('/')) scrapeUrl += '/';
      rootUrl = scrapeUrl;

      _navigateToPageId(widget.initialPageId);
    });

    _progressSubject = BehaviorSubject.seeded(0);
  }

  @override
  void dispose() {
    _progressSubject.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final pageData = _newPage?.data();
    final pageTitle = pageData?.text ?? '';

    return Scaffold(
      // Hide single while pixel around webview
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
      appBar: AppBar(
        title: Text(pageTitle),
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
              ]);
            },
          ),
        ],
      ),
      bottomNavigationBar: _NavigationBar(
        onNext: _newPage != null ? () => _goToNextPage(_newPage!) : null,
        onPrevious:
            _newPage != null ? () => _goToPreviousPage(_newPage!) : null,
        onFirst: () => _goToFirstPage(context),
        onLast: () => _goToLastPage(context),
      ),
      body: Stack(
        children: [
          // WebView wrapper
          Consumer(
            builder: (context, watch, child) {
              return WillPopScope(
                onWillPop: () async {
                  final userComicAsync =
                      context.read(userComicFamily(widget.comicId));
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
                  // Update read stats when exiting, to avoid many doc updates while binge-reading
                  if (_currentPage != null) {
                    var newFromPageId = userComicSnapshot.data()?.newFromPageId;
                    if (newFromPageId == null) {
                      // If there is no "new from page" just set it to the last page
                      final lastPage = await context
                          .read(newestPageFamily(widget.comicId).last);
                      newFromPageId = lastPage?.id;
                    } else {
                      final newFromPageRef = context.read(
                          sharedComicPageRefFamily(SharedComicPageInfo(
                              comicId: widget.comicId, pageId: newFromPageId)));

                      // If reading into the new pages, then set them as not new
                      final newFromPage = await newFromPageRef?.get();
                      final newScrapeTime = newFromPage?.data()?.scrapeTime;
                      final currentScrapeTime =
                          _currentPage!.data()?.scrapeTime;

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
              builder: (context, watch, child) {
                final userComicDocAsync =
                    watch(userComicFamily(widget.comicId));
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
                    // Ignore iframes
                    if (!request.isForMainFrame) {
                      return NavigationDecision.navigate;
                    }

                    final rootHost = Uri.parse(rootUrl).host;
                    final toHost = Uri.parse(request.url).host;

                    // Allow navigation within same website
                    // (check both in case one has www. and one doesn't)
                    if (rootHost.endsWith(toHost) ||
                        toHost.endsWith(rootHost)) {
                      return NavigationDecision.navigate;
                    }

                    // Launch external browser for external URLs
                    await _tryLaunchUrl(request.url);
                    return NavigationDecision.prevent;
                  },
                  onPageStarted: (currentPage) {
                    final pageId = currentPage.split('/').skip(3).join(' ');
                    if (_newPage != null && pageId == _newPage!.id) {
                      // Don't trigger rebuild if we haven't changed page
                      print('Already on page: ' + pageId);
                      return;
                    } else {
                      print('Navigating to page: ' + pageId);
                      setState(() {
                        _newPage = null;
                      });
                    }

                    if (userComicDoc == null) return;

                    final pageRef = context.read(sharedComicPageRefFamily(
                        SharedComicPageInfo(
                            comicId: widget.comicId, pageId: pageId)));

                    // Get data for the new page (don't wait)
                    pageRef?.get().then((value) {
                      if (!value.exists) {
                        print('Page does not exist: ' + pageId);
                        return;
                      }

                      // Update page display
                      setState(() {
                        _newPage = value;
                        _newValidPage = value;
                        print('Got data for page: ' + pageId);
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
        final pageRef = context.read(sharedComicPageRefFamily(
            SharedComicPageInfo(
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
          print('_currentPage is now ' + _currentPage!.id);
        }
      }
    }
  }

  Future<void> _tryLaunchUrl(String? url) async {
    if (url != null && await canLaunch(url)) {
      await launch(url);
    } else {
      final loc = AppLocalizations.of(context)!;
      final displayUrl = url ?? 'null';
      await showErrorDialog(context, loc.webErrorUrl(displayUrl));
    }
  }

  Future<void> _navigateToPageId(String pageId) async {
    final pagePath = pageId.trim().replaceAll(' ', '/');

    // Wait for webview controller to be initialised
    final controller = await _webViewController.future;

    controller.loadUrl(rootUrl + pagePath);
  }

  Future<void> _goToFirstPage(BuildContext context) async {
    final page = await context.read(endPageFamily(SharedComicPagesQueryInfo(
      comicId: widget.comicId,
      descending: false,
    )).future);

    if (page == null) return;

    _navigateToPageId(page.id);
  }

  Future<void> _goToLastPage(BuildContext context) async {
    final page = await context.read(endPageFamily(SharedComicPagesQueryInfo(
      comicId: widget.comicId,
      descending: true,
    )).future);

    if (page == null) return;

    _navigateToPageId(page.id);
  }

  Future<QuerySnapshot<SharedComicPageModel>?> _goToQueriedPage(
    Query<SharedComicPageModel> Function(Query<SharedComicPageModel>)
        getSubQuery,
  ) async {
    if (_newPage == null) return null;

    final pagesQuery =
        context.read(sharedComicPagesQueryFamily(SharedComicPagesQueryInfo(
      comicId: widget.comicId,
      descending: true,
    )));

    if (pagesQuery == null) return null;

    // Get pages below bottom
    final snapshot = await getSubQuery(pagesQuery).get();

    if (snapshot.docs.isEmpty) return null;

    _navigateToPageId(snapshot.docs[0].id);
  }

  Future<void> _goToNextPage(DocumentSnapshot<SharedComicPageModel> fromPage) {
    return _goToQueriedPage(
        (rootQuery) => rootQuery.endBeforeDocument(fromPage).limitToLast(1));
  }

  Future<void> _goToPreviousPage(
      DocumentSnapshot<SharedComicPageModel> fromPage) {
    return _goToQueriedPage(
        (rootQuery) => rootQuery.startAfterDocument(fromPage).limit(1));
  }
}

class _NavigationBar extends StatelessWidget {
  final void Function()? onPrevious;
  final void Function()? onNext;
  final void Function()? onFirst;
  final void Function()? onLast;

  const _NavigationBar({
    Key? key,
    this.onPrevious,
    this.onNext,
    this.onFirst,
    this.onLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryVariant,
      child: SizedBox(
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              color: colorScheme.onPrimary,
              onPressed: onFirst,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: colorScheme.onPrimary,
              onPressed: onPrevious,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              color: colorScheme.onPrimary,
              onPressed: onNext,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              color: colorScheme.onPrimary,
              onPressed: onLast,
            ),
          ],
        ),
      ),
    );
  }
}
