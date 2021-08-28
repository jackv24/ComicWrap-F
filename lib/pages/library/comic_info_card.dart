import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/comic_page/comic_page.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/widgets/card_image_button.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ComicInfoCard extends ConsumerWidget {
  final String comicId;
  final UserComicModel userComic;

  const ComicInfoCard(
      {Key? key, required this.comicId, required this.userComic})
      : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final sharedComicAsync = watch(sharedComicFamily(comicId));
    return sharedComicAsync.when(
      loading: () => Text('Loading...'),
      error: (err, stack) => Text('Error: $err'),
      data: (sharedComic) {
        if (sharedComic == null) return Text('Shared Comic is null');

        var coverImageUrl = sharedComic.coverImageUrl;

        // If cover url is relative, make it absolute
        if (coverImageUrl != null && !coverImageUrl.startsWith('http')) {
          final scrapeUrl = sharedComic.scrapeUrl;
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => ComicPage(comicId: comicId)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5.0),
            Text(
              sharedComic.name ?? comicId,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            SizedBox(height: 2.0),
            TimeAgoText(
                time: userComic.lastReadTime?.toDate(),
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
