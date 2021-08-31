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
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12, top: 6),
              child: Column(
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
                      loading: () => Text('Loading...'),
                      error: (error, stack) => ErrorWidget(error),
                    );
                  }),
                  SizedBox(height: 2),
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
                      loading: () => Text('Loading...'),
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
                  Spacer(),
                  Consumer(
                    builder: (context, watch, child) {
                      final currentPageAsync =
                          watch(currentPageFamily(comicId));
                      return currentPageAsync.when(
                        data: (data) => ElevatedButton.icon(
                          onPressed: data == null || onCurrentPressed == null
                              ? null
                              : () => onCurrentPressed!(data),
                          icon: Icon(Icons.bookmark),
                          label: Expanded(
                            child: Text(
                              data?.data()?.text ?? 'No bookmark',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        loading: () => ElevatedButton.icon(
                          onPressed: null,
                          icon: Icon(Icons.bookmark),
                          label: Expanded(
                            child: Text(
                              'Loading...',
                              overflow: TextOverflow.ellipsis,
                            ),
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
                            icon: Icon(Icons.first_page),
                            label: Text('First')),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                            onPressed: onLastPressed,
                            icon: Icon(Icons.last_page),
                            label: Text('Last')),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
