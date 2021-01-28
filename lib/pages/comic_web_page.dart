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
  @override
  void initState() {
    // Enable hybrid composition on Android
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = widget.pageDoc.data();

    // Construct url from comic and page IDs
    final rootUrl = 'https://${widget.comicDoc.id}/';
    final pagePath = widget.pageDoc.id.trim().replaceAll(' ', '/');
    final wholeUrl = rootUrl + pagePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageData['text'] ?? 'NULL'),
      ),
      body: WebView(
        initialUrl: wholeUrl,
        javascriptMode: JavascriptMode.unrestricted,
        // TODO: switch pageDoc over to new page
        onPageStarted: (currentPage) => print(currentPage),
      ),
    );
  }
}
