import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> startAuth() async {
  await FirebaseAuth.instance.signInAnonymously();
}

Future<void> linkGoogleAuth(BuildContext context) async {
  // Google auth flow
  final googleUser = await GoogleSignIn().signIn();
  final googleAuth = await googleUser.authentication;
  final googleCredential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  try {
    await FirebaseAuth.instance.currentUser
        .linkWithCredential(googleCredential);
  } on FirebaseAuthException catch (e) {
    print('Account link failed with error code: ${e.code}');
    // Account is already linked to another user
    if (e.code == 'credential-already-in-use') {
      // Show dialog to choose whether to cancel or just sign in
      final discardExisting = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error!'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('That account is already linked!'
                      ' Do you want to sign into it instead?'
                      ' (will lose existing data)'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Sign In'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        },
      );

      if (discardExisting) {
        // TODO: Delete anon account (may require re-auth)

        // Sign in with previously authenticated google account
        await FirebaseAuth.instance.signInWithCredential(googleCredential);
      }

      return;
    }
  }

  print("Linked google account");
}
