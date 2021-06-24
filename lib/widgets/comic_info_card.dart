import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:comicwrap_f/pages/comic_page.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
    docStream = widget.userComicSnapshot.data()!.sharedDoc.snapshots();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ComicInfoCard oldWidget) {
    // Make sure we refresh properly when user comic list changes
    if (widget.userComicSnapshot != oldWidget.userComicSnapshot) {
      docStream = widget.userComicSnapshot.data()!.sharedDoc.snapshots();
    }

    super.didUpdateWidget(oldWidget);
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

class CardImageButton extends StatefulWidget {
  final String? coverImageUrl;
  final Function()? onTap;

  const CardImageButton({Key? key, this.coverImageUrl, this.onTap})
      : super(key: key);

  @override
  _CardImageButtonState createState() => _CardImageButtonState();
}

class _CardImageButtonState extends State<CardImageButton> {
  FileInfo? _cachedImage;
  DownloadProgress? _imageDownloadProgress;
  StreamSubscription<FileResponse>? _imageDownloadSub;

  void _subImageDownload() {
    // Stream for cached cover image
    if (widget.coverImageUrl != null) {
      _imageDownloadSub = DefaultCacheManager()
          .getImageFile(widget.coverImageUrl!, withProgress: true)
          .listen((fileResponse) {
        if (fileResponse is FileInfo) {
          setState(() {
            _cachedImage = fileResponse;
            _imageDownloadProgress = null;
          });
        } else if (fileResponse is DownloadProgress) {
          setState(() {
            _imageDownloadProgress = fileResponse;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _subImageDownload();
  }

  @override
  void didUpdateWidget(covariant CardImageButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.coverImageUrl != oldWidget.coverImageUrl) {
      _imageDownloadSub?.cancel();
      _subImageDownload();
    }
  }

  @override
  void dispose() {
    _imageDownloadSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedImage == null) {
      if (_imageDownloadProgress == null) {
        return InkWell(
          onTap: widget.onTap,
          child: Icon(Icons.error, color: Colors.red),
        );
      } else {
        return Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            LinearProgressIndicator(
              value: _imageDownloadProgress!.progress,
              minHeight: 8.0,
            ),
          ],
        );
      }
    } else {
      return Ink.image(
        image: FileImage(_cachedImage!.file),
        fit: BoxFit.cover,
        child: InkWell(
          onTap: widget.onTap,
        ),
      );
    }
  }
}
