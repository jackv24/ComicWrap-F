import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/library/comic_info_card.dart';
import 'package:comicwrap_f/pages/library/sort_button.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/pages/settings/settings_screen.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'add_comic_dialog.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

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
                Consumer(builder: (context, ref, child) {
                  var sortOptionSetting = ref.watch(sortOptionProvider);

                  return SortButton(
                    sortOption: sortOptionSetting.sortOption,
                    reverse: sortOptionSetting.reverse,
                    onSortChange: (option) {
                      switch (option) {
                        case SortChangeOption.lastRead:
                          sortOptionSetting = sortOptionSetting.copyWith(
                              sortOption: SortOption.lastRead);
                          break;
                        case SortChangeOption.lastUpdated:
                          sortOptionSetting = sortOptionSetting.copyWith(
                              sortOption: SortOption.lastUpdated);
                          break;
                        case SortChangeOption.title:
                          sortOptionSetting = sortOptionSetting.copyWith(
                              sortOption: SortOption.title);
                          break;
                        case SortChangeOption.reverse:
                          sortOptionSetting = sortOptionSetting.copyWith(
                              reverse: !sortOptionSetting.reverse);
                          break;
                      }

                      // Save sort options back to settings
                      ref
                          .read(sortOptionProvider.notifier)
                          .setValue(sortOptionSetting);
                    },
                  );
                }),
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
                      final sortOptionSetting = ref.watch(sortOptionProvider);

                      final List<QueryDocumentSnapshot<UserComicModel>>
                          asyncComicsList;

                      switch (sortOptionSetting.sortOption) {
                        case SortOption.lastUpdated:
                          asyncComicsList =
                              ref.watch(userComicsListLastUpdatedProvider);
                          break;

                        case SortOption.lastRead:
                          asyncComicsList =
                              ref.watch(userComicsListLastReadProvider);
                          break;

                        case SortOption.title:
                          asyncComicsList =
                              ref.watch(userComicsListTitleProvider);
                          break;
                      }

                      return _getBodySliver(
                          context, asyncComicsList, sortOptionSetting);
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

  Widget _getBodySliver(
      BuildContext context,
      List<DocumentSnapshot<UserComicModel>>? userComics,
      SortOptionSetting sortOptionSetting) {
    final loc = AppLocalizations.of(context);

    if (userComics == null || userComics.isEmpty) {
      return SliverToBoxAdapter(
        child: Text(loc.libraryEmpty),
      );
    }

    if (sortOptionSetting.reverse) {
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
                  sortOptionDisplay: sortOptionSetting.sortOption,
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
