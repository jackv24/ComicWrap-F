import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      });
    },
  );
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
      case 'empty-auth':
        setState(() {
          _emailErrorText = 'Required';
          _passErrorText = 'Required';
        });
        break;

      case 'empty-email':
        setState(() {
          _emailErrorText = 'Required';
        });
        break;

      case 'empty-pass':
        setState(() {
          _passErrorText = 'Required';
        });
        break;

      case 'user-not-found':
        setState(() {
          _emailErrorText = 'Email is not registered';
        });
        break;

      case 'wrong-password':
        setState(() {
          _passErrorText = 'Wrong password';
        });
        break;

      case null:
        // Close dialog if there were no errors
        Navigator.of(context).pop();
        break;

      default:
        // Unhandled error, just show code
        setState(() {
          _emailErrorText = errorCode;
        });
        break;
    }
  }
}

Future<void> signOut(BuildContext context) async {
  final asyncAuth = ProviderScope.containerOf(context).read(authProvider);
  final auth = asyncAuth.data?.value;
  if (auth == null) {
    // TODO: Show error?
    return;
  }

  await auth.signOut();
}
