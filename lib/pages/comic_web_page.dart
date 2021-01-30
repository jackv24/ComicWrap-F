import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ComicWebPage extends StatefulWidget {
  final DocumentSnapshot comicDoc;
  final DocumentSnapshot pageDoc;

  const ComicWebPage(this.comicDoc, this.pageDoc, {Key key}) : super(key: key);

  @override
  _ComicWebPageState createState() => _ComicWebPageState();
}

class _ComicWebPageState extends State<ComicWebPage> {
  StreamSubscription<DocumentSnapshot> getNewPageSub;
  DocumentSnapshot newPage;

  String _initialUrl;

  @override
  void initState() {
    // Enable hybrid composition on Android
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    // Construct url from comic and page ID
    final rootUrl = 'https://${widget.comicDoc.id}/';
    final pagePath = widget.pageDoc.id.trim().replaceAll(' ', '/');
    _initialUrl = rootUrl + pagePath;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = newPage?.data();
    final pageTitle = pageData != null ? pageData['text'] : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: WebView(
        initialUrl: _initialUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onPageStarted: (currentPage) {
          // We no longer need the data from the previous new page
          if (getNewPageSub != null) {
            getNewPageSub.cancel();
            getNewPageSub = null;
          }

          final pageId = currentPage.split('/').skip(3).join(' ');
          if (newPage != null && pageId == newPage.id) {
            // Don't trigger rebuild if we haven't changed page
            print('Already on page: ' + pageId);
            return;
          } else {
            print('Navigating to page: ' + pageId);
          }

          // Get data for the new page
          getNewPageSub = widget.comicDoc.reference
              .collection('pages')
              .doc(pageId)
              .get()
              .asStream()
              .listen((event) {
            setState(() {
              newPage = event;
              print('Got data for page: ' + pageId);
            });
          });
        },
      ),
    );
  }
}
