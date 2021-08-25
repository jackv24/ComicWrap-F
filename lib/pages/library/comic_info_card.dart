import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/comic_page/comic_page.dart';
import 'package:comicwrap_f/widgets/card_image_button.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';

class ComicInfoCard extends StatefulWidget {
  final DocumentSnapshot<UserComicModel> userComicSnapshot;

  const ComicInfoCard({Key? key, required this.userComicSnapshot})
      : super(key: key);

  @override
  _ComicInfoCardState createState() => _ComicInfoCardState();
}

class _ComicInfoCardState extends State<ComicInfoCard> {
  Stream<DocumentSnapshot<SharedComicModel>>? docStream;

  @override
  void initState() {
    _getNewDocStream();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ComicInfoCard oldWidget) {
    // Make sure we refresh properly when user comic list changes
    if (widget.userComicSnapshot != oldWidget.userComicSnapshot) {
      _getNewDocStream();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _getNewDocStream() {
    docStream = FirebaseFirestore.instance
        .collection('comics')
        .withConverter<SharedComicModel>(
          fromFirestore: (snapshot, _) =>
              SharedComicModel.fromJson(snapshot.data()!),
          toFirestore: (comic, _) => comic.toJson(),
        )
        .doc(widget.userComicSnapshot.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<SharedComicModel>>(
      stream: docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading...');
        }

        final snapshotData = snapshot.data;
        if (snapshotData == null) return Text('Snapshot data is null');

        final data = snapshotData.data();
        if (data == null) return Text('Comic data is null');

        var coverImageUrl = data.coverImageUrl;

        // If cover url is relative, make it absolute
        if (coverImageUrl != null && !coverImageUrl.startsWith('http')) {
          final scrapeUrl = data.scrapeUrl;
          if (scrapeUrl.isNotEmpty) {
            coverImageUrl = scrapeUrl + coverImageUrl;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 210.0 / 297.0,
              child: Material(
                color: Colors.white,
                elevation: 5.0,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                clipBehavior: Clip.antiAlias,
                child: CardImageButton(
                  coverImageUrl: coverImageUrl,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ComicPage(
                            userComicSnapshot: widget.userComicSnapshot,
                            sharedComicSnapshot: snapshotData,
                          ))),
                ),
              ),
            ),
            SizedBox(height: 5.0),
            Text(
              data.name ?? snapshot.data!.id,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            SizedBox(height: 2.0),
            TimeAgoText(
                time: widget.userComicSnapshot.data()!.lastReadTime?.toDate(),
                builder: (text) {
                  return Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle2,
                  );
                }),
          ],
        );
      },
    );
  }
}
