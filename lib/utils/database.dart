import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/models/firestore/user.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final userComicsListProvider =
    StreamProvider<List<DocumentSnapshot<UserComicModel>>?>((ref) {
  final asyncUserDoc = ref.watch(userDocChangesProvider);
  return asyncUserDoc.when(
      loading: () => const Stream.empty(),
      error: (err, stack) => Stream.error(err, stack),
      data: (userDoc) {
        if (userDoc == null) return Stream.value(null);

        return userDoc.reference
            .collection('comics')
            .withConverter<UserComicModel>(
              fromFirestore: (snapshot, _) =>
                  UserComicModel.fromJson(snapshot.data()!),
              toFirestore: (comic, _) => comic.toJson(),
            )
            .snapshots()
            .map((comicsCollectionSnap) {
          // Manually sort documents
          final docs = comicsCollectionSnap.docs;
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
        });
      });
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
