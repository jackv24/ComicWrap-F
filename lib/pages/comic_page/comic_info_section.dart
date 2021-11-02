import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/widgets/card_image_button.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ComicInfoSection extends StatelessWidget {
  final String comicId;
  final void Function(DocumentSnapshot<SharedComicPageModel>)? onCurrentPressed;
  final void Function()? onFirstPressed;
  final void Function()? onLastPressed;

  const ComicInfoSection(
      {Key? key,
      required this.comicId,
      this.onCurrentPressed,
      this.onFirstPressed,
      this.onLastPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coverSection = Material(
      color: Colors.white,
      elevation: 5.0,
      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 210.0 / 297.0,
        child: Material(
          color: Colors.white,
          elevation: 5.0,
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          clipBehavior: Clip.antiAlias,
          child: Consumer(builder: (context, watch, child) {
            final sharedComicAsync = watch(sharedComicFamily(comicId));
            return sharedComicAsync.when(
              data: (data) => CardImageButton(
                coverImageUrl: data?.coverImageUrl,
              ),
              loading: () => const CardImageButton(),
              error: (error, stack) => ErrorWidget(error),
            );
          }),
        ),
      ),
    );

    final infoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(builder: (context, watch, child) {
          final sharedComicAsync = watch(sharedComicFamily(comicId));
          return sharedComicAsync.when(
            data: (data) => Row(
              children: [
                // Show an indicator when still importing or no data
                if (data?.isImporting ?? true) const Icon(Icons.warning),
                Expanded(
                  child: Text(
                    data?.name ?? comicId,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                )
              ],
            ),
            loading: () => const Text('Loading...'),
            error: (error, stack) => ErrorWidget(error),
          );
        }),
        const SizedBox(height: 2),
        Consumer(builder: (context, watch, child) {
          final userComicAsync = watch(userComicFamily(comicId));
          return userComicAsync.when(
            data: (data) => TimeAgoText(
                time: data?.data()?.lastReadTime?.toDate(),
                builder: (text) {
                  return Text(
                    'Read: $text',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle2,
                  );
                }),
            loading: () => const Text('Loading...'),
            error: (error, stack) => ErrorWidget(error),
          );
        }),
        Consumer(builder: (context, watch, child) {
          final newestPageAsync = watch(newestPageFamily(comicId));
          return newestPageAsync.when(
            data: (data) => TimeAgoText(
                time: data?.data()?.scrapeTime?.toDate(),
                builder: (text) {
                  return Text(
                    'Updated: $text',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle2,
                  );
                }),
            loading: () => Text(
              'Updated: ...',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle2,
            ),
            error: (error, stack) => ErrorWidget(error),
          );
        }),
      ],
    );

    final buttonsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(
          builder: (context, watch, child) {
            final currentPageAsync = watch(currentPageFamily(comicId));
            return currentPageAsync.when(
              data: (data) => ElevatedButton.icon(
                onPressed: data == null || onCurrentPressed == null
                    ? null
                    : () => onCurrentPressed!(data),
                icon: const Icon(Icons.bookmark),
                label: Text(
                  data?.data()?.text ?? 'No bookmark',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              loading: () => ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.bookmark),
                label: const Text(
                  'Loading...',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              error: (error, stack) => ErrorWidget(error),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                  onPressed: onFirstPressed,
                  icon: const Icon(Icons.first_page),
                  label: const Text('First')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                  onPressed: onLastPressed,
                  icon: const Icon(Icons.last_page),
                  label: const Text('Last')),
            )
          ],
        )
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > constraints.maxHeight) {
            // Tall layout
            return Row(children: [
              coverSection,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Column(
                    children: [
                      infoSection,
                      const Spacer(),
                      buttonsSection,
                    ],
                  ),
                ),
              ),
            ]);
          } else {
            // Wide layout
            return Column(children: [
              Flexible(child: coverSection),
              Flexible(
                flex: 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      infoSection,
                      const SizedBox(height: 6),
                      buttonsSection,
                    ],
                  ),
                ),
              )
            ]);
          }
        },
      ),
    );
  }
}
