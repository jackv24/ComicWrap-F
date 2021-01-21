import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createUserData() async {
  User currentUser = FirebaseAuth.instance.currentUser;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  await users.doc(currentUser.uid).set({
    'library': [],
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

Future<Stream<DocumentSnapshot>> getUserStream() async {
  User currentUser = FirebaseAuth.instance.currentUser;
  final doc =
      FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

  // Create user data if it doesn't exist (should be created during user sign in)
  if ((await doc.get()).exists == false) await createUserData();

  return doc.snapshots();
}
