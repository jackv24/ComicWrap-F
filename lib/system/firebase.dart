import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const bool USE_EMULATORS = bool.fromEnvironment('USE_EMULATORS');

final firebaseProvider = FutureProvider<FirebaseApp>((ref) async {
  final firebaseApp = await Firebase.initializeApp();

  // Setup connection to emulators if desired
  if (USE_EMULATORS) {
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';

    FirebaseFirestore.instance.settings =
        Settings(host: host + ':8080', sslEnabled: false);
    FirebaseFunctions.instance
        .useFunctionsEmulator(origin: 'http://$host:5001');
    FirebaseAuth.instance.useEmulator('http://$host:9099');
  }

  return firebaseApp;
});
