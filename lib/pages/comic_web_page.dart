import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:universal_io/io.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ComicWebPage extends StatefulWidget {
  final DocumentSnapshot<UserComicModel> userComicDoc;
  final DocumentSnapshot<SharedComicModel> sharedComicDoc;
  final DocumentSnapshot<SharedComicPageModel> initialPageDoc;
  final Future<LazyBox<bool>> pageReadBoxFuture;

  const ComicWebPage(
      {required this.userComicDoc,
      required this.sharedComicDoc,
      required this.initialPageDoc,
      required this.pageReadBoxFuture,
      Key? key})
      : super(key: key);

  @override
  _ComicWebPageState createState() => _ComicWebPageState();
}

class _ComicWebPageState extends State<ComicWebPage> {
  DocumentSnapshot<SharedComicPageModel>? _newPage;

  String? _initialUrl;

  @override
  void initState() {
    // Enable hybrid composition on Android
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    // Construct url from comic and page ID
    final rootUrl = 'https://${widget.sharedComicDoc.id}/';
    final pagePath = widget.initialPageDoc.id.trim().replaceAll(' ', '/');
    _initialUrl = rootUrl + pagePath;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _newPage?.data();
    final pageTitle = pageData?.text ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: WillPopScope(
        onWillPop: () async {
          EasyLoading.show();
          // Update read time when exiting, to avoid many doc updates while binge-reading
          await widget.userComicDoc.reference
              .update({'lastReadTime': Timestamp.now()});
          EasyLoading.dismiss();

          // Pop with value of current page
          Navigator.of(context).pop(_newPage);

          // We manually handle popping above
          return false;
        },
        child: WebView(
          initialUrl: _initialUrl,
          javascriptMode: JavascriptMode.unrestricted,
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
                print('Got data for page: ' + pageId);
              });

              // Don't need to wait for this, just let it happen whenever
              _markPageRead(_newPage!);
            });
          },
        ),
      ),
    );
  }

  void _markPageRead(DocumentSnapshot doc) async {
    final box = await widget.pageReadBoxFuture;
    return box.put(doc.id, true);
  }
}
