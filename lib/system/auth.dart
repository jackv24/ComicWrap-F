import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool _isChangingAuth = false;
bool get isChangingAuth => _isChangingAuth;

Future<void> startAuth() async {
  await FirebaseAuth.instance.signInAnonymously();
}

Future<void> linkGoogleAuth(BuildContext context) async {
  _isChangingAuth = true;

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
      _promptSignIn(context, googleCredential);
      return;
    }
  }

  print("Linked google account");
}

class EmailAuthDetails {
  final String email;
  final String pass;
  const EmailAuthDetails(this.email, this.pass);
}

Future<void> linkEmailAuth(BuildContext context) async {
  final authDetails = await showDialog<EmailAuthDetails>(
    context: context,
    builder: (context) {
      final node = FocusScope.of(context);
      final email = TextEditingController();
      final pass = TextEditingController();

      return AlertDialog(
        title: Text('Email Sign In'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  errorText: 'test error',
                ),
                keyboardType: TextInputType.emailAddress,
                onEditingComplete: () => node.nextFocus(),
                controller: email,
              ),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.security),
                  labelText: 'Password',
                ),
                obscureText: true,
                onSubmitted: (_) {
                  node.unfocus();
                  Navigator.of(context)
                      .pop(EmailAuthDetails(email.text, pass.text));
                },
                controller: pass,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Sign In'),
            onPressed: () {
              Navigator.of(context)
                  .pop(EmailAuthDetails(email.text, pass.text));
            },
          ),
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
        ],
      );
    },
  );

  // Dialog was canceled
  if (authDetails == null) return;

  AuthCredential credential;
  try {
    // Create account for auth details
    credential = EmailAuthProvider.credential(
        email: authDetails.email, password: authDetails.pass);

    // Link email account to existing anonymous account
    await FirebaseAuth.instance.currentUser.linkWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    print('Account link failed with error code: ${e.code}');
    // Account is already linked to another user
    if (e.code == 'credential-already-in-use') {
      _promptSignIn(context, credential);
      return;
    }
  }
}

Future<void> _promptSignIn(
    BuildContext context, AuthCredential signInCredential) async {
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
    // Delete anonymous account
    await FirebaseAuth.instance.currentUser.delete();

    // Sign in with authenticated account
    await FirebaseAuth.instance.signInWithCredential(signInCredential);
  }

  _isChangingAuth = false;
}
