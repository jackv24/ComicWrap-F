import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/error.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final userDocChangesProvider =
    StreamProvider<DocumentSnapshot<UserModel>?>((ref) {
  final asyncUser = ref.watch(userChangesProvider);
  return asyncUser.when(
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err, stack),
    data: (user) {
      if (user == null) return Stream.value(null);

      final firestore = ref.watch(firestoreProvider);
      if (firestore == null) return Stream.value(null);

      return firestore
          .collection('users')
          .withConverter<UserModel>(
            fromFirestore: (snapshot, _) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (comic, _) => comic.toJson(),
          )
          .doc(user.uid)
          .snapshots();
    },
  );
});

final userComicsProvider = StreamProvider<QuerySnapshot<UserComicModel>>((ref) {
  final asyncUserDoc = ref.watch(userDocChangesProvider);
  return asyncUserDoc.when(
      loading: () => const Stream.empty(),
      error: (err, stack) => Stream.error(err, stack),
      data: (userDoc) {
        if (userDoc == null) return const Stream.empty();

        return userDoc.reference
            .collection('comics')
            .withConverter<UserComicModel>(
              fromFirestore: (snapshot, _) =>
                  UserComicModel.fromJson(snapshot.data()!),
              toFirestore: (comic, _) => comic.toJson(),
            )
            .snapshots();
      });
});

final userComicsListLastReadProvider =
    Provider.autoDispose<List<QueryDocumentSnapshot<UserComicModel>>>((ref) {
  final asyncUserComics = ref.watch(userComicsProvider);
  return asyncUserComics.when(
    loading: () => List.empty(),
    error: (err, stack) => List.empty(),
    data: (userComics) {
      final docs = userComics.docs;
      docs.sort((a, b) {
        // Never read sort first
        final aData = a.data();
        if (aData.lastReadTime == null) return -1;

        final bData = b.data();
        if (bData.lastReadTime == null) return 1;

        // Reverse order by read time
        return aData.lastReadTime!.compareTo(bData.lastReadTime!) * -1;
      });
      return docs;
    },
  );
});

class _ComicPair<T> {
  final String comicId;
  final QueryDocumentSnapshot<UserComicModel> userComicSnapshot;
  final T other;

  _ComicPair(this.comicId, this.userComicSnapshot, this.other);
}

final userComicsListLastUpdatedProvider =
    Provider.autoDispose<List<QueryDocumentSnapshot<UserComicModel>>>((ref) {
  final asyncUserComics = ref.watch(userComicsProvider);
  final userComics =
      asyncUserComics.when<List<QueryDocumentSnapshot<UserComicModel>>>(
    loading: () => List.empty(),
    error: (err, stack) => List.empty(),
    data: (userComics) {
      return userComics.docs;
    },
  );

  final comicPairs = userComics.map((userComicSnapshot) {
    final sharedComicPageAsync =
        ref.watch(newestPageFamily(userComicSnapshot.id));
    final sharedComicPage = sharedComicPageAsync.value;
    return _ComicPair(userComicSnapshot.id, userComicSnapshot, sharedComicPage);
  }).toList();

  comicPairs.sort((a, b) {
    final aPageData = a.other?.data();
    final aUpdateTime = aPageData?.scrapeTime;
    if (aUpdateTime == null) return -1;

    final bPageData = b.other?.data();
    final bUpdateTime = bPageData?.scrapeTime;
    if (bUpdateTime == null) return 1;

    return aUpdateTime.compareTo(bUpdateTime) * -1;
  });

  return comicPairs.map((pair) => pair.userComicSnapshot).toList();
});

final userComicsListTitleProvider =
    Provider.autoDispose<List<QueryDocumentSnapshot<UserComicModel>>>((ref) {
  final asyncUserComics = ref.watch(userComicsProvider);
  final userComics =
      asyncUserComics.when<List<QueryDocumentSnapshot<UserComicModel>>>(
    loading: () => List.empty(),
    error: (err, stack) => List.empty(),
    data: (userComics) {
      return userComics.docs;
    },
  );

  final comicPairs = userComics.map((userComicSnapshot) {
    final sharedComicAsync = ref.watch(sharedComicFamily(userComicSnapshot.id));
    final sharedComic = sharedComicAsync.value;
    return _ComicPair(userComicSnapshot.id, userComicSnapshot, sharedComic);
  }).toList();

  comicPairs.sort((a, b) {
    final aName = a.other?.name ?? a.comicId;
    final bName = b.other?.name ?? b.comicId;
    return aName.compareTo(bName);
  });

  return comicPairs.map((pair) => pair.userComicSnapshot).toList();
});

final userComicRefFamily = Provider.autoDispose
    .family<DocumentReference<UserComicModel>?, String>((ref, comicId) {
  final userDocRefAsync = ref.watch(userDocChangesProvider);
  return userDocRefAsync.when(
    loading: () => null,
    error: (err, stack) => null,
    data: (snapshot) {
      if (snapshot == null) return null;

      return snapshot.reference
          .collection('comics')
          .doc(comicId)
          .withConverter<UserComicModel>(
            fromFirestore: (snapshot, _) =>
                UserComicModel.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson(),
          );
    },
  );
});

final userComicFamily = StreamProvider.autoDispose
    .family<DocumentSnapshot<UserComicModel>?, String>((ref, comicId) {
  final userComicRef = ref.watch(userComicRefFamily(comicId));
  return userComicRef?.snapshots() ?? const Stream.empty();
});

final sharedComicFamily = StreamProvider.autoDispose
    .family<SharedComicModel?, String>((ref, comicId) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return Stream.value(null);

  return firestore
      .collection('comics')
      .doc(comicId)
      .withConverter<SharedComicModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      )
      .snapshots()
      .map((snapshot) => snapshot.data());
});

class SharedComicPageInfo {
  final String comicId;
  final String pageId;

  const SharedComicPageInfo({required this.comicId, required this.pageId});
}

final sharedComicPageRefFamily = Provider.autoDispose
    .family<DocumentReference<SharedComicPageModel>?, SharedComicPageInfo>(
        (ref, info) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return null;

  return firestore
      .collection('comics')
      .doc(info.comicId)
      .collection('pages')
      .doc(info.pageId)
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      );
});

final sharedComicPageFamily = StreamProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, SharedComicPageInfo>(
        (ref, info) {
  final comicRef = ref.watch(sharedComicPageRefFamily(info));
  if (comicRef == null) return const Stream.empty();

  return comicRef.snapshots();
});

class SharedComicPagesQueryInfo {
  final String comicId;
  final bool descending;

  const SharedComicPagesQueryInfo(
      {required this.comicId, required this.descending});
}

final sharedComicPagesQueryFamily = Provider.autoDispose
    .family<Query<SharedComicPageModel>?, SharedComicPagesQueryInfo>(
        (ref, info) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return null;

  return firestore
      .collection('comics')
      .doc(info.comicId)
      .collection('pages')
      .orderBy('scrapeTime', descending: info.descending)
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      );
});

final endPageFamily = FutureProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, SharedComicPagesQueryInfo>(
        (ref, info) async {
  final query = ref.watch(sharedComicPagesQueryFamily(info));
  if (query == null) return null;

  final docsSnapshot = await query.limit(1).get();
  if (docsSnapshot.docs.isEmpty) return null;

  return docsSnapshot.docs[0];
});

final newestPageFamily = StreamProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, String>((ref, comicId) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return const Stream.empty();

  return firestore
      .collection('comics')
      .doc(comicId)
      .collection('pages')
      .orderBy('scrapeTime', descending: true)
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      )
      .limit(1)
      .snapshots()
      .map((querySnapshot) {
    final docs = querySnapshot.docs;
    return docs.isNotEmpty ? docs[0] : null;
  });
});

final currentPageFamily = FutureProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, String>((ref, comicId) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return Future.value(null);

  final userComicAsync = ref.watch(userComicFamily(comicId));
  return userComicAsync.when(
    data: (userComicSnapshot) {
      final pageId = userComicSnapshot?.data()?.currentPageId;
      if (pageId == null) return Future.value(null);

      return firestore
          .collection('comics')
          .doc(comicId)
          .collection('pages')
          .doc(pageId)
          .withConverter<SharedComicPageModel>(
            fromFirestore: (snapshot, _) =>
                SharedComicPageModel.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson(),
          )
          .get();
    },
    loading: () => Future.value(null),
    error: (error, stack) => Future.error(error, stack),
  );
});

final newFromPageFamily = FutureProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, String>((ref, comicId) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return Future.value(null);

  final userComicAsync = ref.watch(userComicFamily(comicId));
  return userComicAsync.when(
    data: (userComicSnapshot) {
      final pageId = userComicSnapshot?.data()?.newFromPageId;
      if (pageId == null) return Future.value(null);

      return firestore
          .collection('comics')
          .doc(comicId)
          .collection('pages')
          .doc(pageId)
          .withConverter<SharedComicPageModel>(
            fromFirestore: (snapshot, _) =>
                SharedComicPageModel.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson(),
          )
          .get();
    },
    loading: () => Future.value(null),
    error: (error, stack) => Future.error(error, stack),
  );
});

Future<bool> deleteComicFromLibrary(
    BuildContext context, WidgetRef ref, String comicId) async {
  final userComicAsync = ref.read(userComicFamily(comicId));
  final userComicSnapshot = userComicAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (error, stack) => null,
  );

  if (userComicSnapshot != null) {
    EasyLoading.show();
    await userComicSnapshot.reference.delete();
    EasyLoading.dismiss();

    return true;
  } else {
    final loc = AppLocalizations.of(context);
    await showErrorDialog(context, loc.comicDeleteFail);
    return false;
  }
}
