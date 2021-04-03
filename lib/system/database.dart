import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/system/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

Future<void> deleteUserData() async {
  User currentUser = FirebaseAuth.instance.currentUser!;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  await users.doc(currentUser.uid).delete();

  print('Delete user data');
}

BehaviorSubject<DocumentSnapshot>? _userDocSubject;

Stream<DocumentSnapshot> getUserStream() {
  if (_userDocSubject == null) {
    _userDocSubject = BehaviorSubject<DocumentSnapshot>();

    // NOTE: All this is probably very wrong, but I am confused :(
    // Depends on firebase core to be initialised
    firebaseInit!.then((firebaseApp) {
      // Respond to user auth changes
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) return;
        // Respond to user doc changes
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        docRef.snapshots().listen((snapshot) {
          _userDocSubject!.add(snapshot);
        });
      });
    });
  }

  return _userDocSubject!.stream;
}
