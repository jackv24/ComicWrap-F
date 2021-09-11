import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/library/comic_info_card.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/pages/settings/settings_screen.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'add_comic_dialog.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final asyncComicsList = watch(userComicsListProvider);
    final comicsListWidget = asyncComicsList.when(
      loading: () => SliverToBoxAdapter(
        child: Text("Loading user comics..."),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Text("Error loading user comics."),
      ),
      data: (comicsList) {
        if (comicsList == null) {
          return SliverToBoxAdapter(
            child: Text("User is not signed in (no comics list found)."),
          );
        }

        return _getBodySliver(context, comicsList);
      },
    );

    return MainPageScaffold(
      title: Text('Library'),
      appBarActions: [
        IconButton(
            icon: Icon(
              Icons.library_add,
            ),
            onPressed: () => _onAddPressed(context)),
        IconButton(
            icon: Icon(
              Icons.settings_rounded,
            ),
            onPressed: () => _onSettingsPressed(context)),
      ],
      bodySliver: SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
        sliver: comicsListWidget,
      ),
    );
  }

  void _onAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddComicDialog();
      },
    );
  }

  void _onSettingsPressed(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) {
        return SettingsScreen();
      },
    ));
  }

  Widget _getBodySliver(
      BuildContext context, List<DocumentSnapshot<UserComicModel>> userComics) {
    if (userComics.length == 0) {
      return SliverToBoxAdapter(
        child: Text("User has no comics."),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150.0,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 0.54,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final userComicSnapshot = userComics[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: Duration(milliseconds: 200),
            delay: Duration(milliseconds: 50),
            child: ScaleAnimation(
              scale: 0.85,
              child: FadeInAnimation(
                child: ComicInfoCard(
                  comicId: userComicSnapshot.id,
                  // Snapshot data should never be null since we got it from a collection query
                  userComic: userComicSnapshot.data()!,
                ),
              ),
            ),
          );
        },
        childCount: userComics.length,
      ),
    );
  }
}