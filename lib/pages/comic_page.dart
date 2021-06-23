import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

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

class _PagePair {
  final DocumentSnapshot<SharedComicPageModel> sharedPage;
  final Future<bool?> userPageIsReadFuture;

  const _PagePair(this.sharedPage, this.userPageIsReadFuture);
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

  List<_PagePair> _pages = [];
  ScrollController? _scrollController;
  bool _hasMoreDown = true;
  bool _hasMoreUp = true;
  bool _isLoadingDown = false;
  bool _isLoadingUp = false;

  late Future<LazyBox<bool>> _pageReadBoxFuture;

  late Query<SharedComicPageModel> _pagesQuery;

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
    _scrollController = ScrollController();

    _pageReadBoxFuture = Hive.openLazyBox<bool>(widget.sharedComicSnapshot.id);

    _pagesQuery = widget.sharedComicSnapshot.reference
        .collection('pages')
        .withConverter<SharedComicPageModel>(
          fromFirestore: (snapshot, _) =>
              SharedComicPageModel.fromJson(snapshot.data()!),
          toFirestore: (comic, _) => comic.toJson(),
        )
        .orderBy('scrapeTime', descending: true);

    // Scrollview won't build if we don't have any pages
    _getPages(_ScrollDirection.none);

    super.initState();
  }

  @override
  void dispose() {
    _pageReadBoxFuture.then((value) => value.close());

    super.dispose();
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
          // Draw extra info as side bar on large screens
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                // Extra info side bar
                Container(
                  width: 300,
                  alignment: AlignmentDirectional.topStart,
                  child: ComicInfoSection(
                    userComicRef: widget.userComicSnapshot.reference,
                  ),
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
                    child: ComicInfoSection(
                      userComicRef: widget.userComicSnapshot.reference,
                    ),
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
    final data = page.sharedPage.data()!;
    final title = data.text;

    // Wait to get read state of pages
    return FutureBuilder<bool?>(
      future: page.userPageIsReadFuture,
      builder: (context, snapshot) {
        Widget? trailing;
        if (snapshot.hasError) {
          trailing = Icon(Icons.error);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          trailing = Icon(Icons.refresh);
        }

        // Different appearance for read pages
        final textStyle =
            (snapshot.data ?? false) ? TextStyle(color: Colors.grey) : null;

        return ListTile(
          title: Text(title, style: textStyle),
          trailing: trailing,
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (context) => ComicWebPage(
                userComicDoc: widget.userComicSnapshot,
                sharedComicDoc: widget.sharedComicSnapshot,
                initialPageDoc: page.sharedPage,
                pageReadBoxFuture: _pageReadBoxFuture,
              ),
            ))
                .then((value) {
              if (value is DocumentSnapshot<SharedComicPageModel>) {
                final pageData = value.data();
                final pageTitle = pageData?.text ?? '';
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
          final upQuerySnapshot = await _pagesQuery
              .endBeforeDocument(_pages.first.sharedPage)
              .limitToLast(halfDocLimit)
              .get();

          // If we didn't get all up pages, get more down pages instead
          int downDocLimit = halfDocLimit;
          final upDocsLeft = halfDocLimit - upQuerySnapshot.docs.length;
          if (upDocsLeft > 0) downDocLimit += upDocsLeft;

          // Get pages below bottom
          final downQuerySnapshot = await _pagesQuery
              .startAfterDocument(_pages.last.sharedPage)
              .limit(downDocLimit)
              .get();

          // Insert into pages list
          _addPagesToStart(upQuerySnapshot.docs, halfDocLimit);
          _addPagesToEnd(downQuerySnapshot.docs, downDocLimit);

          // Jump to position centred
          _scrollController!
              .jumpTo(upQuerySnapshot.docs.length * listItemHeight);
        } else {
          // Start from top of list
          final querySnapshot = await _pagesQuery.limit(_initialDocLimit).get();
          _addPagesToEnd(querySnapshot.docs, _initialDocLimit);
        }
        break;

      case _ScrollDirection.down:
        {
          setState(() {
            _isLoadingDown = true;
          });

          // Get more pages from last until limit
          final querySnapshot = await _pagesQuery
              .startAfterDocument(_pages.last.sharedPage)
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
          final querySnapshot = await _pagesQuery
              .endBeforeDocument(_pages.first.sharedPage)
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

  void _centerPagesOn(DocumentSnapshot<SharedComicPageModel> centreDoc) async {
    _pages.clear();
    _pages.add(_PagePair(centreDoc, _getIsUserPageRead(centreDoc)));
    _getPages(_ScrollDirection.none, centredOnDoc: centreDoc);
  }

  Future<bool?> _getIsUserPageRead(
      DocumentSnapshot<SharedComicPageModel> pageDoc) {
    // Start read user doc state here so we only do it once
    return _pageReadBoxFuture.then((box) => box.get(pageDoc.id));
  }

  void _addPagesToEnd(
      List<QueryDocumentSnapshot<SharedComicPageModel>> docs, int limit) {
    // Add to end of list
    _pages.addAll(docs.map((e) => _PagePair(e, _getIsUserPageRead(e))));

    // Don't load any more after this if we reached the end
    if (docs.length < limit) {
      _hasMoreDown = false;
    }
  }

  void _addPagesToStart(
      List<QueryDocumentSnapshot<SharedComicPageModel>> docs, int limit) {
    // Insert at start of list
    _pages.insertAll(0, docs.map((e) => _PagePair(e, _getIsUserPageRead(e))));

    // Don't load any more after this if we reached the start
    if (docs.length < limit) {
      _hasMoreUp = false;
    }
  }
}

class ComicInfoSection extends StatefulWidget {
  final DocumentReference<UserComicModel> userComicRef;

  const ComicInfoSection({Key? key, required this.userComicRef})
      : super(key: key);

  @override
  _ComicInfoSectionState createState() => _ComicInfoSectionState();
}

class _ComicInfoSectionState extends State<ComicInfoSection> {
  late BehaviorSubject<DocumentSnapshot<UserComicModel>> _userComicSubject;
  StreamSubscription<DocumentSnapshot<SharedComicModel>>? _sharedComicStreamSub;
  late BehaviorSubject<DocumentSnapshot<SharedComicModel>> _sharedComicSubject;

  @override
  void initState() {
    _userComicSubject = BehaviorSubject<DocumentSnapshot<UserComicModel>>();
    _sharedComicSubject = BehaviorSubject<DocumentSnapshot<SharedComicModel>>();

    widget.userComicRef.snapshots().listen((userComicSnapshot) {
      _sharedComicStreamSub?.cancel();

      _userComicSubject.add(userComicSnapshot);

      _sharedComicStreamSub = userComicSnapshot
          .data()!
          .sharedDoc
          .snapshots()
          .listen((sharedComicSnapshot) {
        _sharedComicSubject.add(sharedComicSnapshot);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _userComicSubject.close();
    _sharedComicStreamSub!.cancel();
    _sharedComicSubject.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            elevation: 5.0,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 210.0 / 297.0,
              child: Material(
                color: Colors.white,
                elevation: 5.0,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                clipBehavior: Clip.antiAlias,
                child: StreamBuilder<DocumentSnapshot<SharedComicModel>>(
                  stream: _sharedComicSubject.stream,
                  builder: (context, snapshot) {
                    return CardImageButton(
                      coverImageUrl: snapshot.data?.data()!.coverImageUrl,
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot<SharedComicModel>>(
                  stream: _sharedComicSubject.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Text('Loading...');

                    return Text(
                      snapshot.data!.data()!.name ?? snapshot.data!.id,
                      style: Theme.of(context).textTheme.headline5,
                    );
                  },
                ),
                SizedBox(height: 4),
                StreamBuilder<DocumentSnapshot<UserComicModel>>(
                  stream: _userComicSubject.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Text('Loading...');

                    return TimeAgoText(
                        time: snapshot.data!.data()!.lastReadTime?.toDate(),
                        builder: (text) {
                          return Text(
                            'Read: $text',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.subtitle2,
                          );
                        });
                  },
                ),
                Text(
                  'Updated: x days ago',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
                Spacer(),
                ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.bookmark),
                    label: Text('Current')),
                Row(
                  children: [
                    ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.first_page),
                        label: Text('First')),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.last_page),
                        label: Text('Last'))
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
