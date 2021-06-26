import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ComicInfoSection extends StatefulWidget {
  final DocumentReference<UserComicModel> userComicRef;
  final void Function(DocumentSnapshot<SharedComicPageModel>)? onCurrentPressed;
  final void Function()? onFirstPressed;
  final void Function()? onLastPressed;

  const ComicInfoSection(
      {Key? key,
      required this.userComicRef,
      this.onCurrentPressed,
      this.onFirstPressed,
      this.onLastPressed})
      : super(key: key);

  @override
  _ComicInfoSectionState createState() => _ComicInfoSectionState();
}

class _ComicInfoSectionState extends State<ComicInfoSection> {
  late BehaviorSubject<DocumentSnapshot<UserComicModel>> _userComicSubject;
  StreamSubscription<DocumentSnapshot<SharedComicModel>>? _sharedComicStreamSub;
  late BehaviorSubject<DocumentSnapshot<SharedComicModel>> _sharedComicSubject;

  Future<DocumentSnapshot<SharedComicPageModel>>? _sharedComicPageFuture;

  @override
  void initState() {
    _userComicSubject = BehaviorSubject<DocumentSnapshot<UserComicModel>>();
    _sharedComicSubject = BehaviorSubject<DocumentSnapshot<SharedComicModel>>();

    widget.userComicRef.snapshots().listen((userComicSnapshot) {
      _userComicSubject.add(userComicSnapshot);

      _sharedComicPageFuture = userComicSnapshot.data()!.currentPage?.get();

      _sharedComicStreamSub?.cancel();
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
    _sharedComicStreamSub?.cancel();
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
                FutureBuilder<DocumentSnapshot<SharedComicPageModel>>(
                  future: _sharedComicPageFuture,
                  builder: (context, snapshot) {
                    return ElevatedButton.icon(
                      onPressed:
                          !snapshot.hasData || widget.onCurrentPressed == null
                              ? null
                              : () => widget.onCurrentPressed!(snapshot.data!),
                      icon: Icon(Icons.bookmark),
                      label: Text(
                        snapshot.data?.data()!.text ?? 'No current page',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                        onPressed: widget.onFirstPressed,
                        icon: Icon(Icons.first_page),
                        label: Text('First')),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                        onPressed: widget.onLastPressed,
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
