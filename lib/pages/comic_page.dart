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

enum _ScrollDirection {
  none,
  down,
  up,
}

class _ComicPageState extends State<ComicPage> {
  List<_PagePair> pages = [];
  ScrollController _scrollController;
  bool isLoading = false;
  final int initialDocLimit = 20;
  final int moreDocLimit = 10;
  bool hasMoreDown = true;
  bool hasMoreUp = true;

  Query _pagesQuery;

  @override
  void initState() {
    _scrollController = ScrollController();

    _pagesQuery = widget.doc.reference
        .collection('pages')
        .orderBy('index', descending: true);

    // Scrollview won't build if we don't have any pages
    _getPages(_ScrollDirection.none);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final data = doc.data();

    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final minScroll = _scrollController.position.minScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Fetch more documents if user scrolls 20% of device height
      final delta = MediaQuery.of(context).size.height * 0.2;

      final distanceToMax = maxScroll - currentScroll;
      final distanceToMin = currentScroll - minScroll;

      //print('Delta: $delta, To Min: $distanceToMin, To Max: $distanceToMax');

      if (distanceToMax <= delta) {
        _getPages(_ScrollDirection.down);
      } else if (distanceToMin <= delta) {
        _getPages(_ScrollDirection.up);
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

  void _getPages(_ScrollDirection scrollDir,
      {DocumentSnapshot centredOnDoc}) async {
    if (isLoading) {
      return;
    }

    switch (scrollDir) {
      // Reset hasMore flags
      case _ScrollDirection.none:
        hasMoreDown = true;
        hasMoreUp = true;
        break;

      // Cancel if there's no more in the given direction
      case _ScrollDirection.down:
        if (!hasMoreDown) return;
        break;

      case _ScrollDirection.up:
        if (!hasMoreUp) return;
        break;
    }

    print('Loading more pages.. Direction: ${scrollDir.toString()}');

    setState(() {
      isLoading = true;
    });

    switch (scrollDir) {
      case _ScrollDirection.none:
        if (centredOnDoc != null) {
          // TODO: Centre on provided doc
        } else {
          // Start from top of list
          final querySnapshot = await _pagesQuery.limit(initialDocLimit).get();
          _addPagesToEnd(querySnapshot.docs, initialDocLimit);
        }
        break;

      case _ScrollDirection.down:
        {
          // Get more pages from last until limit
          final querySnapshot = await _pagesQuery
              .startAfterDocument(pages.last.sharedPage)
              .limit(moreDocLimit)
              .get();

          _addPagesToEnd(querySnapshot.docs, moreDocLimit);
        }
        break;

      case _ScrollDirection.up:
        {
          // Get more pages from limit until first
          final querySnapshot = await _pagesQuery
              .endBeforeDocument(pages.first.sharedPage)
              .limitToLast(moreDocLimit)
              .get();

          _addPagesToStart(querySnapshot.docs, moreDocLimit);
        }
        break;
    }

    setState(() {
      isLoading = false;
    });
  }

  void _centerPagesOn(DocumentSnapshot centreDoc) async {
    pages.clear();
    pages.add(_PagePair(centreDoc, _getUserPage(centreDoc)));
    _getPages(_ScrollDirection.none, centredOnDoc: centreDoc);
  }

  Future<DocumentSnapshot> _getUserPage(DocumentSnapshot pageDoc) {
    // User should be authenticated
    final userId = FirebaseAuth.instance.currentUser.uid;

    // Start read user doc state here so we only do it once
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('comics')
        .doc(widget.doc.id)
        .collection('readPages')
        .doc(pageDoc.id)
        .get();
  }

  void _addPagesToEnd(List<QueryDocumentSnapshot> docs, int limit) {
    // Add to end of list
    pages.addAll(docs.map((e) => _PagePair(e, _getUserPage(e))));

    // Don't load any more after this if we reached the end
    if (docs.length < limit) {
      hasMoreDown = false;
    }
  }

  void _addPagesToStart(List<QueryDocumentSnapshot> docs, int limit) {
    // Insert at start of list
    pages.insertAll(0, docs.map((e) => _PagePair(e, _getUserPage(e))));

    // Don't load any more after this if we reached the start
    if (docs.length < limit) {
      hasMoreUp = false;
    }
  }
}
