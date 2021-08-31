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

  String? _initialUrl;
  final Completer<WebViewController> _webViewController =
      Completer<WebViewController>();

  late final BehaviorSubject<int> _progressSubject;

  @override
  void initState() {
    super.initState();

    // Enable hybrid composition on Android
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    // Construct url from comic and page ID
    final rootUrl = 'https://${widget.comicId}/';
    final pagePath = widget.initialPageId.trim().replaceAll(' ', '/');
    _initialUrl = rootUrl + pagePath;

    _progressSubject = BehaviorSubject.seeded(0);
  }

  @override
  void dispose() {
    _progressSubject.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _newPage?.data();
    final pageTitle = pageData?.text ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        actions: [
          FutureBuilder<WebViewController>(
            future: _webViewController.future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Icon(Icons.more);
              }

              final controller = snapshot.data!;

              return MoreActionButton(actions: [
                FunctionListItem(
                  child: ListTile(
                    title: Text('Refresh'),
                    trailing: Icon(Icons.refresh),
                  ),
                  onSelected: (context) async {
                    await controller.reload();
                  },
                ),
                FunctionListItem(
                  child: ListTile(
                    title: Text('Open Browser'),
                    trailing: Icon(Icons.open_in_browser),
                  ),
                  onSelected: (context) async {
                    final url = await snapshot.data!.currentUrl();
                    if (url != null && await canLaunch(url)) {
                      await launch(url);
                    } else {
                      final displayUrl = url ?? 'null';
                      await showErrorDialog(
                          context, 'Could not open URL: $displayUrl');
                    }
                  },
                ),
              ]);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView wrapper
          WillPopScope(
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
                  final lastPage =
                      await context.read(newestPageFamily(widget.comicId).last);
                  newFromPageId = lastPage?.id;
                } else {
                  // If reading into the new pages, then set them as not new
                  final newFromPage = await getSharedComicPage(
                          context, widget.comicId, newFromPageId)
                      ?.get();
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
              EasyLoading.dismiss();

              // Pop with value of current page
              Navigator.of(context).pop(_newValidPage);

              // We manually handle popping above
              return false;
            },
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
                  initialUrl: _initialUrl,
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (webViewController) {
                    _webViewController.complete(webViewController);
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

                    // Get data for the new page (don't wait)
                    getSharedComicPage(context, widget.comicId, pageId)
                        ?.get()
                        .then((value) {
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
        _currentPage =
            await getSharedComicPage(context, userComic.id, currentPageId)
                ?.get();
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
          print("_currentPage is now " + _currentPage!.id);
        }
      }
    }
  }
}
