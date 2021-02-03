import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'comic_web_page.dart';

class ComicPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const ComicPage(this.doc, {Key key}) : super(key: key);

  @override
  _ComicPageState createState() => _ComicPageState();
}

class _PagePair {
  final DocumentSnapshot sharedPage;
  final Future<DocumentSnapshot> userPageFuture;

  const _PagePair(this.sharedPage, this.userPageFuture);
}

class _ComicPageState extends State<ComicPage> {
  List<_PagePair> pages = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot lastDocument;
  ScrollController _scrollController;
  final int initialDocLimit = 20;
  final int moreDocLimit = 10;

  Query _pagesQuery;

  @override
  void initState() {
    _scrollController = ScrollController();

    _pagesQuery = widget.doc.reference
        .collection('pages')
        .orderBy('index', descending: true);

    // Scrollview won't build if we don't have any pages
    _getPages();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final data = doc.data();

    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;

      // Fetch more documents if user scrolls 20% of device height
      double delta = MediaQuery.of(context).size.height * 0.2;
      if (maxScroll - currentScroll <= delta) {
        _getPages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name'] ?? doc.id),
      ),
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          pages.length == 0
              ? Center(child: Text('No pages...'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: pages.length,
                  itemBuilder: _listItemBuilder,
                ),
          isLoading
              ? Container(
                  padding: EdgeInsets.all(12),
                  alignment: AlignmentDirectional.bottomCenter,
                  child: CircularProgressIndicator(),
                )
              : Container(),
        ],
      ),
    );
  }

  Widget _listItemBuilder(BuildContext context, int index) {
    final page = pages[index];
    final data = page.sharedPage.data();
    final title = data['text'] ?? '!!Page $index!!';

    // Wait to get read state of pages
    return FutureBuilder<DocumentSnapshot>(
      future: page.userPageFuture,
      builder: (context, snapshot) {
        Widget trailing;
        if (snapshot.hasError) {
          trailing = Icon(Icons.error);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          trailing = Icon(Icons.refresh);
        }

        // Different appearance for read pages
        final textStyle = (snapshot.data?.exists ?? false)
            ? TextStyle(color: Colors.grey)
            : null;

        return ListTile(
          title: Text(title, style: textStyle),
          trailing: trailing,
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (context) => ComicWebPage(widget.doc, page.sharedPage),
            ))
                .then((value) {
              if (value is DocumentSnapshot) {
                final pageData = value?.data();
                final pageTitle = pageData != null ? pageData['text'] : '';
                print('Web Page popped on "$pageTitle" document');
                _centerPagesOn(value);
              } else {
                print('Web Page popped without DocumentSnapshot!');
              }
            });
          },
        );
      },
    );
  }

  void _getPages() async {
    if (!hasMore) {
      return;
    }

    if (isLoading) {
      return;
    }

    print('Loading more pages');

    setState(() {
      isLoading = true;
    });

    QuerySnapshot querySnapshot;
    int documentLimit;
    if (lastDocument == null) {
      documentLimit = initialDocLimit;
      querySnapshot = await _pagesQuery.limit(documentLimit).get();
    } else {
      documentLimit = moreDocLimit;
      querySnapshot = await _pagesQuery
          .startAfterDocument(lastDocument)
          .limit(documentLimit)
          .get();
    }

    final docs = querySnapshot.docs;
    if (docs.length < documentLimit) {
      hasMore = false;

      // No pages were loaded at all, so cancel early
      if (docs.length <= 0) {
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    lastDocument = docs.last;

    // Add all new pages
    docs.forEach(_addPage);

    setState(() {
      isLoading = false;
    });
  }

  void _centerPagesOn(DocumentSnapshot centreDoc) async {
    // TODO
  }

  void _addPage(QueryDocumentSnapshot pageDoc) {
    // User should be authenticated
    final userId = FirebaseAuth.instance.currentUser.uid;

    // Start read user doc state here so we only do it once
    final readDocFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('comics')
        .doc(widget.doc.id)
        .collection('readPages')
        .doc(pageDoc.id)
        .get();

    pages.add(_PagePair(pageDoc, readDocFuture));
  }
}
