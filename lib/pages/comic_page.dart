import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:comicwrap_f/widgets/comic_info_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'comic_web_page.dart';

const listItemHeight = 50.0;

class ComicPage extends StatefulWidget {
  final DocumentSnapshot<UserComicModel> userComicSnapshot;
  final DocumentSnapshot<SharedComicModel> sharedComicSnapshot;

  const ComicPage(
      {Key? key,
      required this.userComicSnapshot,
      required this.sharedComicSnapshot})
      : super(key: key);

  @override
  _ComicPageState createState() => _ComicPageState();
}

enum _ScrollDirection {
  none,
  down,
  up,
}

class _FunctionListItem {
  final String text;
  final Future Function(BuildContext) onSelected;

  const _FunctionListItem(this.text, this.onSelected);
}

class _ComicPageState extends State<ComicPage> {
  final int _initialDocLimit = 30;
  final int _moreDocLimit = 10;

  List<DocumentSnapshot<SharedComicPageModel>> _pages = [];
  ScrollController? _scrollController;
  bool _hasMoreDown = true;
  bool _hasMoreUp = true;
  bool _isLoadingDown = false;
  bool _isLoadingUp = false;

  Future<DocumentSnapshot<SharedComicPageModel>>? _currentPageFuture;

  late final Query<SharedComicPageModel> _basePagesQuery = widget
      .sharedComicSnapshot.reference
      .collection('pages')
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (comic, _) => comic.toJson(),
      );

  // Lazy init so we can access widget inside
  late var _moreOptions = [
    _FunctionListItem('Delete', (context) async {
      EasyLoading.show();
      await widget.userComicSnapshot.reference.delete();
      EasyLoading.dismiss();

      // This comic has now been removed, so close it's page
      Navigator.of(context).pop();
    }),
  ];

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    // Load initial pages for scrollview
    final currentPageRef = widget.userComicSnapshot.data()!.currentPage;
    if (currentPageRef != null) {
      // Centre on current page
      _currentPageFuture = currentPageRef.get();
      _currentPageFuture!.then((snapshot) {
        _centerPagesOn(snapshot);
      });
    } else {
      // Start at top if no current page
      _getPages(_ScrollDirection.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scrollController!.addListener(() {
      final maxScroll = _scrollController!.position.maxScrollExtent;
      final minScroll = _scrollController!.position.minScrollExtent;
      final currentScroll = _scrollController!.position.pixels;

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
        actions: [
          PopupMenuButton(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.more_horiz),
            ),
            itemBuilder: (context) {
              return List.generate(_moreOptions.length, (index) {
                return PopupMenuItem(
                  value: index,
                  child: Text(_moreOptions[index].text),
                );
              });
            },
            onSelected: (int index) => _moreOptions[index].onSelected(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final comicInfo = ComicInfoSection(
            userComicRef: widget.userComicSnapshot.reference,
            onCurrentPressed: _centerPagesOn,
            onFirstPressed:
                _pages.length > 0 ? () => _goToEndPage(false) : null,
            onLastPressed:
                _pages.length > 0 ? () => _goToEndPage(true) : null,
          );

          // Draw extra info as side bar on large screens
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                // Extra info side bar
                Container(
                  width: 300,
                  alignment: AlignmentDirectional.topStart,
                  child: comicInfo,
                ),
                // Page List
                Expanded(
                    child: _buildList(
                        context, EdgeInsets.symmetric(horizontal: 8)))
              ],
            );
          } else {
            return Container(
              child: Column(
                children: [
                  // Extra info top bar
                  Container(
                    height: 200,
                    alignment: AlignmentDirectional.topStart,
                    child: comicInfo,
                  ),
                  // Page List
                  Expanded(
                      child: _buildList(
                          context, EdgeInsets.symmetric(vertical: 4)))
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, EdgeInsetsGeometry listPadding) {
    return Card(
      elevation: 5,
      margin: EdgeInsetsDirectional.zero,
      shape: ContinuousRectangleBorder(),
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          _pages.length == 0
              ? Center(child: Text('No pages...'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _pages.length,
                  itemBuilder: _listItemBuilder,
                  itemExtent: listItemHeight,
                  padding: listPadding,
                ),
          _isLoadingDown
              ? Container(
                  padding: EdgeInsets.all(12),
                  alignment: AlignmentDirectional.bottomCenter,
                  child: CircularProgressIndicator(),
                )
              : Container(),
          _isLoadingUp
              ? Container(
                  padding: EdgeInsets.all(12),
                  alignment: AlignmentDirectional.topCenter,
                  child: CircularProgressIndicator(),
                )
              : Container(),
        ],
      ),
    );
  }

  Widget _listItemBuilder(BuildContext context, int index) {
    final page = _pages[index];
    final data = page.data()!;
    final title = data.text;

    // Wait to get read state of pages
    return FutureBuilder<DocumentSnapshot<SharedComicPageModel>>(
      future: _currentPageFuture,
      builder: (context, snapshot) {
        Widget? trailing;
        if (snapshot.hasError) {
          trailing = Icon(Icons.error);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          trailing = Icon(Icons.refresh);
        }

        final currentPageTime = snapshot.data?.data()!.scrapeTime;
        final isRead;
        if (currentPageTime != null && data.scrapeTime != null) {
          isRead = data.scrapeTime!.compareTo(currentPageTime) <= 0;
        } else {
          isRead = false;
        }

        // Different appearance for read pages
        final textStyle = isRead ? TextStyle(color: Colors.grey) : null;

        return ListTile(
          title: Text(title, style: textStyle),
          trailing: trailing,
          onTap: () => _openWebPage(page),
        );
      },
    );
  }

  void _openWebPage(DocumentSnapshot<SharedComicPageModel> sharedPage) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (context) => ComicWebPage(
        userComicDoc: widget.userComicSnapshot,
        sharedComicDoc: widget.sharedComicSnapshot,
        initialPageDoc: sharedPage,
      ),
    ))
        .then((value) async {
      if (value is DocumentSnapshot<SharedComicPageModel>) {
        _currentPageFuture = Future.value(value);

        final pageData = value.data();
        final pageTitle = pageData?.text ?? '';
        print('Web Page popped on "$pageTitle" document');
        _centerPagesOn(value);
      } else {
        print('Web Page popped without DocumentSnapshot!');
      }
    });
  }

  void _goToEndPage(bool descending) async {
    EasyLoading.show();

    final snapshot = await _basePagesQuery
        .orderBy('scrapeTime', descending: descending)
        .limit(1)
        .get();

    if (snapshot.docs.length > 0) {
      await _centerPagesOn(snapshot.docs[0]);
    }

    EasyLoading.dismiss();
  }

  Future<void> _getPages(_ScrollDirection scrollDir,
      {DocumentSnapshot? centredOnDoc}) async {
    if (_isLoadingUp || _isLoadingDown) {
      return;
    }

    switch (scrollDir) {
      // Reset hasMore flags
      case _ScrollDirection.none:
        _hasMoreDown = true;
        _hasMoreUp = true;
        break;

      // Cancel if there's no more in the given direction
      case _ScrollDirection.down:
        if (!_hasMoreDown) return;
        break;

      case _ScrollDirection.up:
        if (!_hasMoreUp) return;
        break;
    }

    print('Loading more pages.. Direction: ${scrollDir.toString()}');

    final pagesQuery = _basePagesQuery.orderBy('scrapeTime', descending: true);

    switch (scrollDir) {
      case _ScrollDirection.none:
        setState(() {
          _isLoadingUp = true;
          _isLoadingDown = true;
        });

        // Get pages before and after centre page
        if (centredOnDoc != null) {
          final halfDocLimit = (_initialDocLimit / 2).round();

          // Get page above top
          final upQuerySnapshot = await pagesQuery
              .endBeforeDocument(centredOnDoc)
              .limitToLast(halfDocLimit)
              .get();

          // If we didn't get all up pages, get more down pages instead
          int downDocLimit = halfDocLimit;
          final upDocsLeft = halfDocLimit - upQuerySnapshot.docs.length;
          if (upDocsLeft > 0) downDocLimit += upDocsLeft;

          // Get pages below bottom
          final downQuerySnapshot = await pagesQuery
              .startAfterDocument(centredOnDoc)
              .limit(downDocLimit)
              .get();

          // Insert into pages list
          _addPagesToStart(upQuerySnapshot.docs, halfDocLimit);
          _addPagesToEnd(downQuerySnapshot.docs, downDocLimit);

          // Jump to position centred
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
            _scrollController!
                .jumpTo(max(upQuerySnapshot.docs.length - 1, 0) * listItemHeight);
          });
        } else {
          // Start from top of list
          final querySnapshot = await pagesQuery.limit(_initialDocLimit).get();
          _addPagesToEnd(querySnapshot.docs, _initialDocLimit);
        }
        break;

      case _ScrollDirection.down:
        {
          setState(() {
            _isLoadingDown = true;
          });

          // Get more pages from last until limit
          final querySnapshot = await pagesQuery
              .startAfterDocument(_pages.last)
              .limit(_moreDocLimit)
              .get();

          _addPagesToEnd(querySnapshot.docs, _moreDocLimit);
        }
        break;

      case _ScrollDirection.up:
        {
          setState(() {
            _isLoadingUp = true;
          });

          // Get more pages from limit until first
          final querySnapshot = await pagesQuery
              .endBeforeDocument(_pages.first)
              .limitToLast(_moreDocLimit)
              .get();

          _addPagesToStart(querySnapshot.docs, _moreDocLimit);

          // Compensate scroll position since we're adding to the top
          _scrollController!.jumpTo(_scrollController!.position.pixels +
              (querySnapshot.docs.length * listItemHeight));
        }
        break;
    }

    setState(() {
      _isLoadingDown = false;
      _isLoadingUp = false;
    });
  }

  Future<void> _centerPagesOn(DocumentSnapshot<SharedComicPageModel> centreDoc) async {
    _pages.clear();
    await _getPages(_ScrollDirection.none, centredOnDoc: centreDoc);
  }

  void _addPagesToEnd(
      List<QueryDocumentSnapshot<SharedComicPageModel>> docs, int limit) {
    // Add to end of list
    _pages.addAll(docs);

    // Don't load any more after this if we reached the end
    if (docs.length < limit) {
      _hasMoreDown = false;
    }
  }

  void _addPagesToStart(
      List<QueryDocumentSnapshot<SharedComicPageModel>> docs, int limit) {
    // Insert at start of list
    _pages.insertAll(0, docs);

    // Don't load any more after this if we reached the start
    if (docs.length < limit) {
      _hasMoreUp = false;
    }
  }
}
