import 'dart:async';

import 'package:comicwrap_f/system/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase.dart';

final userChangesProvider = StreamProvider<User?>((ref) {
  // Firebase needs to be initialised before we can use it
  return ref.watch(authProvider).when(
        data: (auth) => auth?.authStateChanges() ?? Stream.empty(),
        loading: () => Stream.empty(),
        error: (err, stack) => Stream.error(err, stack),
      );
});

Future<void> linkGoogleAuth(BuildContext context) async {
  //_isChangingAuth = true;

  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    // TODO: Show error?
    return;
  }

  // Google auth flow
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) {
    //_isChangingAuth = false;
    return;
  }

  final googleAuth = await googleUser.authentication;
  final googleCredential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  try {
    await auth.currentUser!.linkWithCredential(googleCredential);
  } on FirebaseAuthException catch (e) {
    print('Account link failed with error code: ${e.code}');
    // Account is already linked to another user
    if (e.code == 'credential-already-in-use') {
      _promptSignIn(context, auth, googleCredential);
      return;
    }
  }

  print("Linked google account");
}

class EmailAuthDetails {
  String email;
  String pass;

  EmailAuthDetails(this.email, this.pass);
}

Future<void> linkEmailAuth(BuildContext context) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    // TODO: Show error?
    return;
  }

  await showDialog(
    context: context,
    builder: (context) {
      return EmailLoginDialog((authDetails) async {
        // Firebase just given unknown error if any details are empty
        if (authDetails.email.isEmpty) {
          if (authDetails.pass.isEmpty) {
            return 'empty-auth';
          } else {
            return 'empty-email';
          }
        } else if (authDetails.pass.isEmpty) {
          return 'empty-pass';
        }

        AuthCredential credential;
        try {
          // Create account for auth details
          credential = EmailAuthProvider.credential(
              email: authDetails.email, password: authDetails.pass);

          // Link email account to existing anonymous account
          await auth.currentUser!.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          print('Account link failed with error code: ${e.code}');
          // Return error back to dialog to display to user
          return e.code;
        }
        // No errors! :D
        return null;
      });
    },
  );
}

Future<bool> _promptSignIn(BuildContext context, FirebaseAuth auth,
    AuthCredential signInCredential) async {
  // Show dialog to choose whether to cancel or just sign in
  final discardExisting = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error!'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('That account is already linked!'
                      ' Do you want to sign into it instead?'
                      ' (will lose existing data)'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Sign In'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        },
      ) ??
      false;

  try {
    if (discardExisting) {
      // In case it wasn't set already
      //_isChangingAuth = true;

      final firestore =
          ProviderScope.containerOf(context).read(firestoreProvider);
      if (firestore == null) {
        // TODO: Show error?
        return false;
      }

      // Delete anonymous account
      await deleteUserData(auth, firestore);
      await auth.currentUser!.delete();

      // Sign in with authenticated account
      await auth.signInWithCredential(signInCredential);
    }
  } finally {
    //_isChangingAuth = false;
  }

  return discardExisting;
}

class EmailLoginDialog extends StatefulWidget {
  final Future<String?> Function(EmailAuthDetails authDetails) onSubmitAuth;

  const EmailLoginDialog(this.onSubmitAuth, {Key? key}) : super(key: key);

  @override
  _EmailLoginDialogState createState() => _EmailLoginDialogState();
}

class _EmailLoginDialogState extends State<EmailLoginDialog> {
  String? _emailErrorText;
  String? _passErrorText;

  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _preventPop = false;

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);

    return WillPopScope(
      onWillPop: () async => !_preventPop,
      child: AlertDialog(
        title: Text('Email Sign In'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  errorText: _emailErrorText,
                ),
                keyboardType: TextInputType.emailAddress,
                onEditingComplete: () => node.nextFocus(),
                controller: _email,
                enabled: !_preventPop,
              ),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.security),
                  labelText: 'Password',
                  errorText: _passErrorText,
                ),
                obscureText: true,
                onSubmitted: (_) {
                  node.unfocus();
                  _submit(context);
                },
                controller: _pass,
                enabled: !_preventPop,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Sign In'),
            onPressed: _preventPop ? null : () => _submit(context),
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed:
                _preventPop ? null : () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    // Clear previous error while waiting for auth
    setState(() {
      _emailErrorText = null;
      _passErrorText = null;
      _preventPop = true;
    });

    String? errorCode =
        await widget.onSubmitAuth(EmailAuthDetails(_email.text, _pass.text));

    setState(() {
      _preventPop = false;
    });

    switch (errorCode) {
      case 'invalid-email':
        setState(() {
          _emailErrorText = errorCode;
        });
        return;

      case 'weak-password':
        setState(() {
          _passErrorText = errorCode;
        });
        return;

      case 'empty-auth':
        setState(() {
          _emailErrorText = 'Required';
          _passErrorText = 'Required';
        });
        return;

      case 'empty-email':
        setState(() {
          _emailErrorText = 'Required';
        });
        return;

      case 'empty-pass':
        setState(() {
          _passErrorText = 'Required';
        });
        return;

      case 'email-already-in-use':
        final credential = EmailAuthProvider.credential(
            email: _email.text, password: _pass.text);

        setState(() {
          _preventPop = true;
        });

        final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
        final auth = asyncAuth.data?.value;
        if (auth == null) {
          // TODO: Show error?
          return;
        }

        bool signedIn = false;
        try {
          signedIn = await _promptSignIn(context, auth, credential);
        } on FirebaseAuthException catch (e) {
          print('Email sign in failed with error code: ${e.code}');
          switch (e.code) {
            case 'wrong-password':
              // TODO: Find a way to not delete anon user before signing in
              await auth.signInAnonymously();

              setState(() {
                _passErrorText = e.code;
              });
              break;
          }
        }

        setState(() {
          _preventPop = false;
        });

        // Don't close login dialog if we didn't sign in
        if (!signedIn) return;

        break;
    }

    // Close dialog if there were no errors
    Navigator.of(context).pop();
  }
}
