import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore/user.dart';
import 'package:comicwrap_f/models/firestore/user_comic.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:comicwrap_f/system/firebase.dart';
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
