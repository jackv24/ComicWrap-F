import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');
final _host =
    defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

final firebaseProvider = FutureProvider<FirebaseApp>((ref) async {
  return await Firebase.initializeApp();
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final app = ref.watch(firebaseProvider).value;
  if (app == null) return null;

  final firestore = FirebaseFirestore.instance;
  if (useEmulators) {
    firestore.settings = Settings(host: '$_host:8090', sslEnabled: false);
  }
  return firestore;
});

final functionsProvider = Provider<FirebaseFunctions?>((ref) {
  final app = ref.watch(firebaseProvider).value;
  if (app == null) return null;

  final functions = FirebaseFunctions.instance;
  if (useEmulators) {
    functions.useFunctionsEmulator(_host, 5001);
  }
  return functions;
});

final authProvider = FutureProvider<FirebaseAuth?>((ref) async {
  final app = ref.watch(firebaseProvider).value;
  if (app == null) return null;

  final auth = FirebaseAuth.instance;
  if (useEmulators) {
    await auth.useAuthEmulator(_host, 9099);
  }
  return auth;
});
