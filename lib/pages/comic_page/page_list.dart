import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_list.freezed.dart';

enum PageListStartType {
  current,
  first,
  last,
}

@freezed
class PageListStartParams with _$PageListStartParams {
  factory PageListStartParams({
    required String comicId,
    required PageListStartType startType,
  }) = _PageListStartParams;
}

final pageListStartProvider = FutureProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, PageListStartParams>(
        (ref, params) async {
  switch (params.startType) {
    case PageListStartType.current:
      return ref.watch(_initialPageListStart(params.comicId).future);
    case PageListStartType.first:
      return ref.watch(endPageFamily(SharedComicPagesQueryInfo(
        comicId: params.comicId,
        descending: false,
      )).future);
    case PageListStartType.last:
      return ref.watch(endPageFamily(SharedComicPagesQueryInfo(
        comicId: params.comicId,
        descending: true,
      )).future);
  }
});

final _initialPageListStart = FutureProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, String>(
        (ref, comicId) async {
  final userComicDoc = await ref.watch(userComicFamily(comicId).future);

  final currentPageId = userComicDoc?.data()?.currentPageId;

  // Get ref to current page once for centering pages on start
  final currentPageRef = currentPageId != null
      ? ref.watch(sharedComicPageRefFamily(
          SharedComicPageInfo(comicId: comicId, pageId: currentPageId)))
      : null;

  if (currentPageRef != null) {
    // Centre on current page
    return currentPageRef.get();
  } else {
    final firstPage = await ref.watch(endPageFamily(SharedComicPagesQueryInfo(
      comicId: comicId,
      descending: false,
    )).future);

    // Start at first page if no current page
    if (firstPage != null) {
      return firstPage;
    } else {
      return null;
    }
  }
});
