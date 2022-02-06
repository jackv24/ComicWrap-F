import 'package:badges/badges.dart';
import 'package:comicwrap_f/constants.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/comic_page/comic_page.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/download.dart';
import 'package:comicwrap_f/widgets/card_image_button.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ComicInfoCard extends ConsumerWidget {
  final String comicId;
  final UserComicModel userComic;

  const ComicInfoCard(
      {Key? key, required this.comicId, required this.userComic})
      : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final loc = AppLocalizations.of(context);

    final sharedComicAsync = watch(sharedComicFamily(comicId));
    final newFromPageAsync = watch(newFromPageFamily(comicId));
    final newestPageAsync = watch(newestPageFamily(comicId));

    // If there is no newest page, we can assume there are no pages at all
    final hasNewestPage = newestPageAsync.maybeWhen(
        data: (data) => data != null, orElse: () => false);

    final newFromTime = newFromPageAsync.maybeWhen(
        data: (data) => data?.data()?.scrapeTime, orElse: () => null);
    final newestPageTime = newestPageAsync.maybeWhen(
        data: (data) => data?.data()?.scrapeTime, orElse: () => null);

    final hasNewPage = newFromTime != null &&
        newestPageTime != null &&
        newestPageTime.compareTo(newFromTime) > 0;

    return sharedComicAsync.when(
      loading: () => Text(loc.loadingText),
      error: (err, stack) => Text('Error: $err'),
      data: (sharedComic) {
        if (sharedComic == null) return const Text('Shared Comic is null');

        final coverImageUrl = getValidCoverImageUrl(
            sharedComic.coverImageUrl, sharedComic.scrapeUrl);

        final theme = Theme.of(context);

        // Block opening comic page under certain conditions, with different displays
        final Widget? blocker;
        if (sharedComic.isImporting) {
          blocker = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                loc.comicImporting,
                style: theme.textTheme.caption,
              ),
            ],
          );
        } else if (!hasNewestPage) {
          blocker = Center(
            child: Text(
              loc.comicNoPages,
              style: theme.textTheme.caption,
            ),
          );
        } else {
          blocker = null;
        }

        final card = Stack(
          alignment: Alignment.center,
          children: [
            CardImageButton(
              coverImageUrl: coverImageUrl,
              // Don't allow tapping through while blocker is up
              onTap: blocker != null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => ComicPage(comicId: comicId)),
                      ),
              onLongPressed: (offset) => _showPopupMenu(context, offset),
            ),
            if (blocker != null)
              IgnorePointer(
                  child: Container(
                color: theme.colorScheme.surface.withAlpha(170),
              )),
            if (blocker != null) IgnorePointer(child: blocker),
          ],
        );

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
                  elevation: 5.0,
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  clipBehavior: Clip.antiAlias,
                  child: Tooltip(
                    // Tooltip is just used for finding comic in integration tests
                    triggerMode: TooltipTriggerMode.manual,
                    message: sharedComic.name ?? comicId,
                    child: card,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              sharedComic.name ?? comicId,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            const SizedBox(height: 2.0),
            TimeAgoText(
                time: userComic.lastReadTime,
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

  void _showPopupMenu(BuildContext context, Offset? offset) async {
    if (offset == null) return;

    final screenSize = MediaQuery.of(context).size;
    final loc = AppLocalizations.of(context);

    final func = await showMenu<Future<void> Function(BuildContext)>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        screenSize.width - offset.dx,
        screenSize.height - offset.dy,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            title: Text(loc.comicReportIssue),
            trailing: const Icon(Icons.report),
          ),
          value: (context) => launch(githubNewIssueUrl),
        ),
        PopupMenuItem(
          child: ListTile(
            title: Text(loc.delete),
            trailing: const Icon(Icons.delete),
          ),
          value: (context) => deleteComicFromLibrary(context, comicId),
        ),
      ],
    );

    if (func != null) await func(context);
  }
}
