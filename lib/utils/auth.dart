import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:comicwrap_f/utils/error.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

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
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.value;
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
    print('Firebase Google auth failed with error code: ${e.code}');
  }
}

Future<void> signOut(BuildContext context) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.value;
  if (auth == null) {
    await _showGetAuthError(context);
    return;
  }

  EasyLoading.show();
  await auth.signOut();
  EasyLoading.dismiss();
}

Future<String?> deleteAccount(
    BuildContext context, WidgetRef ref, String password) async {
  final user = await ref.read(userChangesProvider.future);
  if (user == null) {
    // ignore: use_build_context_synchronously
    showErrorDialog(context, 'User is null');
    return 'User is null';
  }

  EasyLoading.show();

  try {
    // Re-auth first to verify password
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        // All our auth methods use email, so it can't be null
        email: user.email!,
        password: password,
      ),
    );
    // Delete the user
    await user.delete();
  } on FirebaseAuthException catch (e) {
    EasyLoading.dismiss();
    return e.code;
  }

  EasyLoading.dismiss();
  return null;
}

Future<void> _showGetAuthError(BuildContext context) {
  return showErrorDialog(context, 'Couldn\'t get FirebaseAuth!');
}

Future<String?> submitSignIn(
    BuildContext context, EmailSignInDetails authDetails) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.value;
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
  final auth = asyncAuth.value;
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

// Created with help from https://firebase.flutter.dev/docs/auth/social/#apple
Future<void> linkAppleAuth(BuildContext context) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.value;
  if (auth == null) {
    await _showGetAuthError(context);
    return;
  }

  // To prevent replay attacks with the credential returned from Apple, we
  // include a nonce in the credential request. When signing in with
  // Firebase, the nonce in the id token returned by Apple, is expected to
  // match the sha256 hash of `rawNonce`.
  final rawNonce = generateNonce();
  final nonce = sha256ofString(rawNonce);

  final AuthorizationCredentialAppleID appleCredential;

  try {
    // Request credential for the currently signed in Apple account.
    appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    print('Apple sign in failed with error code: ${e.code}');
    return;
  }

  // Create an `OAuthCredential` from the credential returned by Apple.
  final oauthCredential = OAuthProvider('apple.com').credential(
    idToken: appleCredential.identityToken,
    rawNonce: rawNonce,
  );

  try {
    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    await auth.signInWithCredential(oauthCredential);
  } on FirebaseAuthException catch (e) {
    print('Firebase Apple auth failed with error code: ${e.code}');
  }
}

/// Generates a cryptographically secure random nonce, to be included in a
/// credential request.
String generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

/// Returns the sha256 hash of [input] in hex notation.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
