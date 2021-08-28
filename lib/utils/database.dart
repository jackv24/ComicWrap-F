import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/shared_comic.dart';
import 'package:comicwrap_f/models/firestore/user.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:comicwrap_f/utils/auth/auth.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDocChangesProvider =
    StreamProvider<DocumentSnapshot<UserModel>?>((ref) {
  final asyncUser = ref.watch(userChangesProvider);
  return asyncUser.when(
    loading: () => Stream.empty(),
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
      loading: () => Stream.empty(),
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
  return userComicRef?.snapshots() ?? Stream.empty();
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

final sharedComicPageFamily = StreamProvider.autoDispose
    .family<DocumentSnapshot<SharedComicPageModel>?, SharedComicPageInfo>(
        (ref, info) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return Stream.value(null);

  return firestore
      .collection('comics')
      .doc(info.comicId)
      .collection('pages')
      .doc(info.pageId)
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      )
      .snapshots();
});

DocumentReference<SharedComicPageModel>? getSharedComicPage(
    BuildContext context, String comicId, String pageId) {
  final firestore = context.read(firestoreProvider);
  if (firestore == null) return null;

  return firestore
      .collection('comics')
      .doc(comicId)
      .collection('pages')
      .doc(pageId)
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      );
}

Query<SharedComicPageModel>? getSharedComicPagesQuery(
    BuildContext context, String comicId,
    {required bool descending}) {
  final firestore = context.read(firestoreProvider);
  if (firestore == null) return null;

  return firestore
      .collection('comics')
      .doc(comicId)
      .collection('pages')
      .orderBy('scrapeTime', descending: descending)
      .withConverter<SharedComicPageModel>(
        fromFirestore: (snapshot, _) =>
            SharedComicPageModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      );
}

final newestPageFamily = FutureProvider.autoDispose
    .family<SharedComicPageModel?, String>((ref, comicId) async {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return null;

  final snapshot = await firestore
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
      .get();

  final docs = snapshot.docs;
  if (docs.isEmpty) return null;

  return docs[0].data();
});
