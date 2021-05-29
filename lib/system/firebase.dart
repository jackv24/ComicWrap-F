import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'auth.dart';

const bool USE_EMULATORS = bool.fromEnvironment('USE_EMULATORS');

Future<FirebaseApp>? _firebaseInit;

Future<FirebaseApp> get firebaseInit {
  if (_firebaseInit == null) _firebaseInit = Firebase.initializeApp();
  return _firebaseInit!;
}

BehaviorSubject<User?>? _authSubject;
Future<void>? _startAuth;

Stream<User?> getAuthStream() {
  if (_authSubject == null) {
    _authSubject = BehaviorSubject<User?>();

    // Wait for firebase to initialise
    firebaseInit.then((firebaseApp) {
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

      // Start listening to auth changes here (build shouldn't have side effects)
      FirebaseAuth.instance.authStateChanges().listen((user) {
        // If user is not authenticated, authenticate them
        if (user == null && !isChangingAuth && _startAuth == null) {
          _startAuth = startAuth();
        }

        // Re-emit event for StreamBuilder
        _authSubject!.add(user);
      });
    });
  }

  return _authSubject!.stream;
}
