import 'dart:async';

import 'package:comicwrap_f/utils/error.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class EmailSignInDetails {
  String email;
  String pass;

  EmailSignInDetails(this.email, this.pass);
}

class EmailSignUpDetails {
  String email;
  String passA;
  String passB;

  EmailSignUpDetails(this.email, this.passA, this.passB);
}

final userChangesProvider = StreamProvider<User?>((ref) {
  // Firebase needs to be initialised before we can use it
  return ref.watch(authProvider).when(
        data: (auth) => auth?.authStateChanges() ?? const Stream.empty(),
        loading: () => const Stream.empty(),
        error: (err, stack) => Stream.error(err, stack),
      );
});

Future<void> linkGoogleAuth(BuildContext context) async {
  //_isChangingAuth = true;

  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    await _showGetAuthError(context);
    return;
  }

  final GoogleSignInAccount? googleUser;
  try {
    // Google auth flow
    googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // Google sign in was canceled
      return;
    }
  } on PlatformException catch (e) {
    print('Google sign in failed with error code: ${e.code}');
    return;
  }

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  try {
    await auth.signInWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    print('Firebase google auth failed with error code: ${e.code}');
  }
}

Future<void> signOut(BuildContext context) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    await _showGetAuthError(context);
    return;
  }

  EasyLoading.show();
  await auth.signOut();
  EasyLoading.dismiss();
}

Future<void> _showGetAuthError(BuildContext context) {
  return showErrorDialog(context, 'Couldn\'t get FirebaseAuth!');
}

Future<String?> submitSignIn(
    BuildContext context, EmailSignInDetails authDetails) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    await _showGetAuthError(context);
    return 'no-auth-provider';
  }

  // Firebase just gives unknown error if any details are empty
  if (authDetails.email.isEmpty) {
    if (authDetails.pass.isEmpty) {
      return 'empty-auth';
    } else {
      return 'empty-email';
    }
  } else if (authDetails.pass.isEmpty) {
    return 'empty-pass';
  }

  try {
    await auth.signInWithCredential(EmailAuthProvider.credential(
        email: authDetails.email, password: authDetails.pass));
  } on FirebaseAuthException catch (e) {
    print('Account link failed with error code: ${e.code}');
    // Return error back to dialog to handle
    return e.code;
  }
  // No errors! :D
  return null;
}

Future<String?> submitSignUp(
    BuildContext context, EmailSignUpDetails authDetails) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    await _showGetAuthError(context);
    return 'no-auth-provider';
  }

  final String matchingPass;

  // Firebase just gives unknown error if any details are empty
  if (authDetails.email.isEmpty) {
    if (authDetails.passA.isEmpty) {
      return 'empty-auth';
    } else {
      return 'empty-email';
    }
  } else if (authDetails.passA.isEmpty) {
    return 'empty-pass';
  } else if (authDetails.passB != authDetails.passA) {
    // Passwords need to match!
    return 'pass-not-match';
  } else {
    matchingPass = authDetails.passA;
  }

  try {
    await auth.createUserWithEmailAndPassword(
        email: authDetails.email, password: matchingPass);
  } on FirebaseAuthException catch (e) {
    print('Account create failed with error code: ${e.code}');
    // Return error back to dialog to handle
    return e.code;
  }
  // No errors! :D
  return null;
}