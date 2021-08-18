import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:rxdart/subjects.dart';
import 'package:universal_io/io.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ComicWebPage extends StatefulWidget {
  final DocumentSnapshot<UserComicModel> userComicDoc;
  final DocumentSnapshot<SharedComicModel> sharedComicDoc;
  final DocumentSnapshot<SharedComicPageModel> initialPageDoc;

  const ComicWebPage(
      {required this.userComicDoc,
      required this.sharedComicDoc,
      required this.initialPageDoc,
      Key? key})
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
    final rootUrl = 'https://${widget.sharedComicDoc.id}/';
    final pagePath = widget.initialPageDoc.id.trim().replaceAll(' ', '/');
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
          // Refresh button
          FutureBuilder<WebViewController>(
            future: _webViewController.future,
            builder: (context, snapshot) {
              return IconButton(
                icon: Icon(Icons.refresh),
                onPressed: !snapshot.hasData
                    ? null
                    : () async {
                        await snapshot.data!.reload();
                      },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView wrapper
          WillPopScope(
            onWillPop: () async {
              EasyLoading.show();
              // Update read stats when exiting, to avoid many doc updates while binge-reading
              if (_currentPage != null) {
                await widget.userComicDoc.reference.update({
                  'lastReadTime': Timestamp.now(),
                  'currentPage': sharedComicPageToJson(_currentPage!.reference),
                });
              } else {
                // Don't set currentPage reference if it's null
                await widget.userComicDoc.reference.update({
                  'lastReadTime': Timestamp.now(),
                });
              }
              EasyLoading.dismiss();

              // Pop with value of current page
              Navigator.of(context).pop(_newValidPage);

              // We manually handle popping above
              return false;
            },
            child: WebView(
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

                // Get data for the new page (don't wait)
                widget.sharedComicDoc.reference
                    .collection('pages')
                    .withConverter<SharedComicPageModel>(
                      fromFirestore: (snapshot, _) =>
                          SharedComicPageModel.fromJson(snapshot.data()!),
                      toFirestore: (comic, _) => comic.toJson(),
                    )
                    .doc(pageId)
                    .get()
                    .then((value) {
                  // Update page display
                  setState(() {
                    _newPage = value;
                    _newValidPage = value;
                    print('Got data for page: ' + pageId);
                  });

                  // Don't need to wait for this, just let it happen whenever
                  _markPageRead(_newPage!);
                });
              },
              onProgress: (progress) => _progressSubject.add(progress),
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

  void _markPageRead(DocumentSnapshot<SharedComicPageModel> doc) async {
    // Try and get existing current page to compare scrape time
    if (_currentPage == null) {
      _currentPage = await widget.userComicDoc.data()!.currentPage?.get();
    }

    final docScrapeTime = doc.data()!.scrapeTime;
    final currentPageScrapeTime = _currentPage?.data()!.scrapeTime;

    // Only record as current if doc page has been scraped
    if (docScrapeTime != null) {
      // If we don't have a current page then just make this the current
      if (_currentPage == null) {
        _currentPage = doc;
      } else {
        // Otherwise make this the current if it's newer than the previous
        if (currentPageScrapeTime != null &&
            currentPageScrapeTime.compareTo(docScrapeTime) < 0) {
          _currentPage = doc;
          print("_currentPage is now " + _currentPage!.id);
        }
      }
    }
  }
}
