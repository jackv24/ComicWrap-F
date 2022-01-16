import 'dart:async';

import 'package:appwrite/models.dart';
import 'package:comicwrap_f/utils/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final userChangesProvider = StreamProvider.autoDispose<User>((ref) {
  final realtime = ref.watch(realtimeProvider);
  final subscription = realtime.subscribe(['account']);

  ref.onDispose(() => subscription.close());

  return subscription.stream.map((event) => User.fromMap(event.payload));
});

// Future<void> linkGoogleAuth(BuildContext context) async {
//   //_isChangingAuth = true;
//
//   final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
//   final auth = asyncAuth.data?.value;
//   if (auth == null) {
//     await _showGetAuthError(context);
//     return;
//   }
//
//   final GoogleSignInAccount? googleUser;
//   try {
//     // Google auth flow
//     googleUser = await GoogleSignIn().signIn();
//     if (googleUser == null) {
//       // Google sign in was canceled
//       return;
//     }
//   } on PlatformException catch (e) {
//     print('Google sign in failed with error code: ${e.code}');
//     return;
//   }
//
//   final googleAuth = await googleUser.authentication;
//   final credential = GoogleAuthProvider.credential(
//     accessToken: googleAuth.accessToken,
//     idToken: googleAuth.idToken,
//   );
//
//   try {
//     await auth.signInWithCredential(credential);
//   } on FirebaseAuthException catch (e) {
//     print('Firebase google auth failed with error code: ${e.code}');
//   }
// }

Future<void> signOut(BuildContext context) async {
  final account = ProviderScope.containerOf(context).read(accountProvider);

  EasyLoading.show();
  final sessions = await account.getSessions();
  final List<Future> futures = [];
  for (final session in sessions.sessions) {
    // Only delete the current session
    if (!session.current) continue;
    futures.add(account.deleteSession(sessionId: session.$id));
  }
  await Future.wait(futures);
  EasyLoading.dismiss();
}

Future<String?> submitSignIn(
    BuildContext context, EmailSignInDetails authDetails) async {
  // Don't allow fields to be empty
  if (authDetails.email.isEmpty) {
    if (authDetails.pass.isEmpty) {
      return 'empty-auth';
    } else {
      return 'empty-email';
    }
  } else if (authDetails.pass.isEmpty) {
    return 'empty-pass';
  }

  final account = ProviderScope.containerOf(context).read(accountProvider);
  final session = await account.createSession(
      email: authDetails.email, password: authDetails.pass);

  // TODO: Do anything with session?

  // No errors! :D
  return null;
}

Future<String?> submitSignUp(
    BuildContext context, EmailSignUpDetails authDetails) async {
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

  final account = ProviderScope.containerOf(context).read(accountProvider);
  final result = await account.create(
      userId: 'unique()', email: authDetails.email, password: matchingPass);

  // TODO: Do something with result?

  // No errors! :D
  return null;
}
