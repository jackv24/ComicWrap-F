import 'package:firebase_core/firebase_core.dart';

Future<FirebaseApp>? _firebaseInit;

Future<FirebaseApp>? get firebaseInit {
  if (_firebaseInit == null) _firebaseInit = Firebase.initializeApp();
  return _firebaseInit;
}
