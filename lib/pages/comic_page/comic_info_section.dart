import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/download.dart';
import 'package:comicwrap_f/widgets/card_image_button.dart';
import 'package:comicwrap_f/widgets/time_ago_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ComicInfoSection extends StatelessWidget {
  final String comicId;
  final void Function(DocumentSnapshot<SharedComicPageModel>)? onCurrentPressed;
  final void Function()? onFirstPressed;
  final void Function()? onLastPressed;

  const ComicInfoSection({
    Key? key,
    required this.comicId,
    this.onCurrentPressed,
    this.onFirstPressed,
    this.onLastPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final coverSection = Material(
      elevation: 5.0,
      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 210.0 / 297.0,
        child: Material(
          elevation: 5.0,
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          clipBehavior: Clip.antiAlias,
          child: Consumer(builder: (context, watch, child) {
            final sharedComicAsync = watch(sharedComicFamily(comicId));
            return sharedComicAsync.when(
              data: (data) => CardImageButton(
                coverImageUrl: data?.coverImageUrl,
              ),
              loading: () => CardImageButton(),
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
            data: (data) => Text(
              data?.name ?? comicId,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headline5,
            ),
            loading: () => Text(loc.loadingText),
            error: (error, stack) => ErrorWidget(error),
          );
        }),
        const SizedBox(height: 2),
        Consumer(builder: (context, watch, child) {
          final userComicAsync = watch(userComicFamily(comicId));
          return userComicAsync.when(
            data: (data) => TimeAgoText(
                time: data?.data()?.lastReadTime,
                builder: (text) {
                  return Text(
                    loc.infoRead(text),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle2,
                  );
                }),
            loading: () => Text(loc.loadingText),
            error: (error, stack) => ErrorWidget(error),
          );
        }),
        Consumer(builder: (context, watch, child) {
          final newestPageAsync = watch(newestPageFamily(comicId));
          return newestPageAsync.when(
            data: (data) => TimeAgoText(
                time: data?.data()?.scrapeTime,
                builder: (text) {
                  return Text(
                    loc.infoUpdated(text),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle2,
                  );
                }),
            loading: () => Text(
              loc.infoUpdated('...'),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle2,
            ),
            error: (error, stack) => ErrorWidget(error),
          );
        }),
      ],
    );

    final buttonsSection = Consumer(builder: (context, watch, child) {
      final paletteGenAsync = watch(downloadCoverImagePaletteFamily(comicId));
      final paletteGen = paletteGenAsync.when(
        data: (data) => data,
        loading: () => null,
        error: (error, stack) => null,
      );

      final Color? buttonColor;
      switch (Theme.of(context).brightness) {
        case Brightness.dark:
          buttonColor = paletteGen?.lightVibrantColor?.color;
          break;
        case Brightness.light:
          buttonColor = paletteGen?.vibrantColor?.color;
          break;
        default:
          buttonColor = null;
          break;
      }

      final ButtonStyle? buttonStyle;
      if (buttonColor != null) {
        buttonStyle = ElevatedButton.styleFrom(primary: buttonColor);
      } else {
        buttonStyle = null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              Expanded(child: Consumer(
                builder: (context, watch, child) {
                  final currentPageAsync = watch(currentPageFamily(comicId));
                  return currentPageAsync.when(
                    data: (data) => ElevatedButton.icon(
                      onPressed: data == null || onCurrentPressed == null
                          ? null
                          : () => onCurrentPressed!(data),
                      icon: const Icon(Icons.bookmark),
                      label: Text(
                        data?.data()?.text ?? loc.infoNoBookmark,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: buttonStyle,
                    ),
                    loading: () => ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.bookmark),
                      label: Text(
                        loc.loadingText,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: buttonStyle,
                    ),
                    error: (error, stack) => ErrorWidget(error),
                  );
                },
              ))
            ],
          ),
          Flex(
            direction: Axis.horizontal,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onFirstPressed,
                  icon: const Icon(Icons.first_page),
                  label: Text(loc.buttonFirst, overflow: TextOverflow.ellipsis),
                  style: buttonStyle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLastPressed,
                  icon: const Icon(Icons.last_page),
                  label: Text(loc.buttonLast, overflow: TextOverflow.ellipsis),
                  style: buttonStyle,
                ),
              )
            ],
          )
        ],
      );
    });

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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
