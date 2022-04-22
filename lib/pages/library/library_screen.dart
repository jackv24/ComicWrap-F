import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/pages/library/comic_info_card.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/pages/settings/settings_screen.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'add_comic_dialog.dart';

const String bannerAdId = String.fromEnvironment(
  'AD_ID_LIBRARY_BANNER_BOT',
  // Default is the Admob Banner Ad test ID
  defaultValue: 'ca-app-pub-3940256099942544/6300978111',
);

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  BannerAd? bannerAd;
  bool isBannerAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only load ad once (this method is called when modal dialogs pop up also)
    if (bannerAd == null) {
      _loadAd();
    }
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

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
                IconButton(
                    icon: const Icon(
                      Icons.library_add,
                    ),
                    onPressed: () => _onAddPressed(context)),
                IconButton(
                    icon: const Icon(
                      Icons.settings_rounded,
                    ),
                    onPressed: () => _onSettingsPressed(context)),
              ],
              bodySliver: SliverPadding(
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
              ),
            ),
          ),
          if (bannerAd != null && isBannerAdLoaded)
            Container(
              alignment: Alignment.center,
              child: AdWidget(ad: bannerAd!),
              width: bannerAd!.size.width.toDouble(),
              height: bannerAd!.size.height.toDouble(),
            )
        ],
      ),
    );
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (size == null) {
      print('Unable to get height of anchored banner.');
      return;
    }

    bannerAd = BannerAd(
      adUnitId: bannerAdId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Banner ad failed to load: $err');
          ad.dispose();
        },
      ),
    );

    return bannerAd!.load();
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
