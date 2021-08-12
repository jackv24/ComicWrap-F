import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDocChangesProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final asyncUser = ref.watch(userChangesProvider);
  return asyncUser.when(
    loading: () => Stream.empty(),
    error: (err, stack) => Stream.error(err, stack),
    data: (user) => user != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
        : Stream.value(null),
  );
});

Future<void> deleteUserData() async {
  // TODO: use riverpod
  User currentUser = FirebaseAuth.instance.currentUser!;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  await users.doc(currentUser.uid).delete();

  print('Delete user data');
}

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
