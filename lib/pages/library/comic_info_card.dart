import 'package:badges/badges.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedComicAsync = ref.watch(sharedComicFamily(comicId));
    final newFromPageAsync = ref.watch(newFromPageFamily(comicId));
    final newestPageAsync = ref.watch(newestPageFamily(comicId));

    final newFromTime = newFromPageAsync.maybeWhen(
        data: (data) => data?.data()?.scrapeTime, orElse: () => null);
    final newestPageTime = newestPageAsync.maybeWhen(
        data: (data) => data?.data()?.scrapeTime, orElse: () => null);

    final hasNewPage = newFromTime != null &&
        newestPageTime != null &&
        newestPageTime.compareTo(newFromTime) > 0;

    return sharedComicAsync.when(
      loading: () => const Text('Loading...'),
      error: (err, stack) => Text('Error: $err'),
      data: (sharedComic) {
        if (sharedComic == null) return const Text('Shared Comic is null');

        var coverImageUrl = sharedComic.coverImageUrl;

        // If cover url is relative, make it absolute
        if (coverImageUrl != null && !coverImageUrl.startsWith('http')) {
          final scrapeUrl = sharedComic.scrapeUrl;
          if (scrapeUrl.isNotEmpty) {
            coverImageUrl = scrapeUrl + coverImageUrl;
          }
        }

        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Badge(
              showBadge: hasNewPage,
              badgeColor: theme.colorScheme.secondary,
              badgeContent: Icon(
                Icons.new_releases,
                color: theme.colorScheme.background,
                size: 18,
              ),
              child: AspectRatio(
                aspectRatio: 210.0 / 297.0,
                child: Material(
                  color: Colors.white,
                  elevation: 5.0,
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  clipBehavior: Clip.antiAlias,
                  child: Tooltip(
                    message: sharedComic.name ?? comicId,
                    child: CardImageButton(
                      coverImageUrl: coverImageUrl,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => ComicPage(comicId: comicId)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            Row(
              children: [
                // Show an indicator when still importing
                if (sharedComic.isImporting)
                  const Icon(
                    Icons.warning,
                    size: 18.0,
                  ),
                // Title fill rest of the space
                Expanded(
                  child: Text(
                    sharedComic.name ?? comicId,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.0),
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
