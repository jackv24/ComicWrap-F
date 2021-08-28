import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/pages/comic_page/comic_info_section.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/error.dart';
import 'package:comicwrap_f/widgets/more_action_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comic_web_page/comic_web_page.dart';

const listItemHeight = 50.0;

class ComicPage extends StatefulWidget {
  final String comicId;

  const ComicPage({Key? key, required this.comicId}) : super(key: key);

  @override
  _ComicPageState createState() => _ComicPageState();
}

enum _ScrollDirection {
  none,
  down,
  up,
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

  TapDownDetails? _listTapDownDetails;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    // Get providers one time on start - these shouldn't fail but handle it gracefully if they do
    final userComicAsync = context.read(userComicFamily(widget.comicId));
    final currentPageId = userComicAsync.when(
      data: (data) => data?.data()?.currentPageId,
      loading: () => null,
      error: (error, stack) => null,
    );

    // Get ref to current page once for centering pages on start
    final currentPageRef = currentPageId != null
        ? getSharedComicPage(context, widget.comicId, currentPageId)
        : null;

    if (currentPageRef != null) {
      // Centre on current page
      _centerPagesOnRef(currentPageRef);
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
          MoreActionButton(actions: [
            FunctionListItem(
              child: ListTile(
                title: Text('Delete'),
                trailing: Icon(Icons.delete),
              ),
              onSelected: (context) async {
                final userComicAsync =
                    context.read(userComicFamily(widget.comicId));
                final userComicSnapshot = userComicAsync.when(
                  data: (data) => data,
                  loading: () => null,
                  error: (error, stack) => null,
                );

                if (userComicSnapshot != null) {
                  EasyLoading.show();
                  await userComicSnapshot.reference.delete();
                  EasyLoading.dismiss();

                  // This comic has now been removed, so close it's page
                  Navigator.of(context).pop();
                } else {
                  await showErrorDialog(
                      context, 'Failed to delete: couldn\'t get user comic');
                }
              },
            ),
          ]),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final comicInfo = ComicInfoSection(
            comicId: widget.comicId,
            onCurrentPressed: _centerPagesOnDoc,
            onFirstPressed:
                _pages.length > 0 ? () => _goToEndPage(false) : null,
            onLastPressed: _pages.length > 0 ? () => _goToEndPage(true) : null,
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
      child: SafeArea(
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
      ),
    );
  }

  Widget _listItemBuilder(BuildContext context, int index) {
    final page = _pages[index];
    final data = page.data()!;
    final title = data.text;

    // Only text style changes
    final titleText = Consumer(builder: (context, watch, child) {
      final userComicAsync = watch(userComicFamily(widget.comicId));

      // Derive isRead by comparing to current page
      final isRead = userComicAsync.when(
        loading: () => false,
        error: (error, stack) => false,
        data: (snapshot) {
          final pageScrapeTime = data.scrapeTime;
          if (pageScrapeTime == null) return false;

          final userComic = snapshot?.data();
          if (userComic == null) return false;

          final currentPageId = userComic.currentPageId;
          if (currentPageId == null) return false;

          final currentPageAsync = watch(sharedComicPageFamily(
              SharedComicPageInfo(
                  comicId: widget.comicId, pageId: currentPageId)));

          final currentPage = currentPageAsync.when(
            data: (data) => data,
            loading: () => null,
            error: (error, stack) => null,
          );

          final currentScrapeTime = currentPage?.data()?.scrapeTime;
          if (currentScrapeTime == null) return false;

          return pageScrapeTime.compareTo(currentScrapeTime) <= 0;
        },
      );

      // Different appearance for read pages
      final textStyle = isRead ? TextStyle(color: Colors.grey) : null;
      return Text(title, style: textStyle);
    });

    return GestureDetector(
      onTapDown: (details) => _listTapDownDetails = details,
      child: ListTile(
        title: titleText,
        onTap: () => _openWebPage(page.id),
        onLongPress: () async {
          final offset = _listTapDownDetails!.globalPosition;
          final val = await showMenu(
              context: context,
              position: RelativeRect.fromLTRB(offset.dx, offset.dy, 0, 0),
              items: [
                PopupMenuItem(value: page.id, child: Text('Set Bookmark'))
              ]);
          if (val != null) _setPageAsCurrent(val);
        },
      ),
    );
  }

  void _openWebPage(String pageId) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (context) => ComicWebPage(
        comicId: widget.comicId,
        initialPageId: pageId,
      ),
    ))
        .then((value) async {
      if (value is DocumentSnapshot<SharedComicPageModel>) {
        final pageData = value.data();
        final pageTitle = pageData?.text ?? '';
        print('Web Page popped on "$pageTitle" document');
        _centerPagesOnDoc(value);
      } else {
        print('Web Page popped without DocumentSnapshot!');
      }
    });
  }

  void _goToEndPage(bool descending) async {
    final pagesQuery = getSharedComicPagesQuery(context, widget.comicId,
        descending: descending);
    if (pagesQuery == null) return;

    EasyLoading.show();

    final snapshot = await pagesQuery.limit(1).get();

    if (snapshot.docs.length > 0) {
      await _centerPagesOnDoc(snapshot.docs[0]);
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

    final pagesQuery =
        getSharedComicPagesQuery(context, widget.comicId, descending: true);
    if (pagesQuery == null) return;

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
            _scrollController!.jumpTo(
                max(upQuerySnapshot.docs.length - 1, 0) * listItemHeight);
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

  Future<void> _centerPagesOnRef(
      DocumentReference<SharedComicPageModel> centreDocRef) async {
    final centreDoc = await centreDocRef.get();
    return _centerPagesOnDoc(centreDoc);
  }

  Future<void> _centerPagesOnDoc(
      DocumentSnapshot<SharedComicPageModel> centreDoc) async {
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

  void _setPageAsCurrent(String pageId) async {
    final userComic = context.read(userComicRefFamily(widget.comicId));

    if (userComic == null) {
      await showErrorDialog(context,
          'Failed to set page as current: couldn\'t get user comic ref.');
      return;
    }

    EasyLoading.show();
    await userComic.update({'currentPageId': pageId});
    EasyLoading.dismiss();
  }
}
