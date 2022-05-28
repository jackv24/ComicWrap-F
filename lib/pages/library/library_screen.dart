import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/library/comic_info_card.dart';
import 'package:comicwrap_f/pages/library/sort_button.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/pages/settings/settings_screen.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'add_comic_dialog.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  SortOption _sortOption = SortOption.lastUpdated;
  bool _sortReverse = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: MainPageScaffold(
              title: loc.libraryTitle,
              appBarActions: [
                SortButton(
                  sortOption: _sortOption,
                  reverse: _sortReverse,
                  onSortChange: (option) {
                    setState(() {
                      switch (option) {
                        case SortChangeOption.lastUpdated:
                          _sortOption = SortOption.lastUpdated;
                          break;
                        case SortChangeOption.lastRead:
                          _sortOption = SortOption.lastRead;
                          break;
                        case SortChangeOption.title:
                          _sortOption = SortOption.title;
                          break;
                        case SortChangeOption.reverse:
                          _sortReverse = !_sortReverse;
                          break;
                      }
                    });
                  },
                ),
                IconButton(
                    icon: const Icon(
                      Icons.settings_rounded,
                    ),
                    onPressed: () => _onSettingsPressed(context)),
              ],
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.library_add),
                onPressed: () => _onAddPressed(context),
              ),
              bodySlivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 15.0),
                  sliver: Consumer(
                    builder: (context, ref, child) {
                      final asyncComicsList = ref.watch(userComicsListProvider);
                      return asyncComicsList.when(
                        loading: () => SliverToBoxAdapter(
                          child: Text(loc.loadingText),
                        ),
                        error: (err, stack) => SliverToBoxAdapter(
                          child: Text(loc.libraryError),
                        ),
                        data: (comicsList) {
                          return _getBodySliver(context, comicsList);
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _onAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const AddComicDialog();
      },
    );
  }

  void _onSettingsPressed(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) {
        return const SettingsScreen();
      },
    ));
  }

  Widget _getBodySliver(BuildContext context,
      List<DocumentSnapshot<UserComicModel>>? userComics) {
    final loc = AppLocalizations.of(context);

    if (userComics == null || userComics.isEmpty) {
      return SliverToBoxAdapter(
        child: Text(loc.libraryEmpty),
      );
    }

    switch (_sortOption) {
      case SortOption.title:
      // TODO: Implement

      case SortOption.lastUpdated:
      // TODO: Implement

      case SortOption.lastRead:
        userComics.sort((a, b) {
          // Never read sort first
          final aData = a.data();
          if (aData == null || aData.lastReadTime == null) return -1;

          final bData = b.data();
          if (bData == null || bData.lastReadTime == null) return 1;

          // Reverse order by read time
          return aData.lastReadTime!.compareTo(bData.lastReadTime!) * -1;
        });
        break;
    }

    if (_sortReverse) {
      userComics = userComics.reversed.toList();
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
          final userComicSnapshot = userComics![index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: const Duration(milliseconds: 200),
            delay: const Duration(milliseconds: 50),
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
