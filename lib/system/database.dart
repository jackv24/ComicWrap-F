import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createUserData() async {
  User currentUser = FirebaseAuth.instance.currentUser;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  await users.doc(currentUser.uid).set({
    'dummyData': 42,
  });

  print('Added user data');
}

Future<void> deleteUserData() async {
  User currentUser = FirebaseAuth.instance.currentUser;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  await users.doc(currentUser.uid).delete();

  print('Delete user data');
}

// https://www.goodbyetohalos.com/comic/prologue-1
// -> comics > www.goodbyetohalos.com > pages > comic prologue-1

Stream<QuerySnapshot> getComicsStream() {
  return FirebaseFirestore.instance.collection('comics').snapshots();
}
