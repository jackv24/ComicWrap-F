import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  String email;
  String pass;

  EmailAuthDetails(this.email, this.pass);
}

Future<void> linkEmailAuth(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) {
      return EmailLoginDialog((authDetails) async {
        // Firebase just given unknown error if any details are empty
        if (authDetails.email?.isEmpty ?? true) {
          if (authDetails.pass?.isEmpty ?? true) {
            return 'empty-auth';
          } else {
            return 'empty-email';
          }
        } else if (authDetails.pass?.isEmpty ?? true) {
          return 'empty-pass';
        }

        AuthCredential credential;
        try {
          // Create account for auth details
          credential = EmailAuthProvider.credential(
              email: authDetails.email, password: authDetails.pass);

          // Link email account to existing anonymous account
          await FirebaseAuth.instance.currentUser
              .linkWithCredential(credential);
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

class EmailLoginDialog extends StatefulWidget {
  final Future<String> Function(EmailAuthDetails authDetails) onSubmitAuth;

  const EmailLoginDialog(this.onSubmitAuth, {Key key}) : super(key: key);

  @override
  _EmailLoginDialogState createState() => _EmailLoginDialogState();
}

class _EmailLoginDialogState extends State<EmailLoginDialog> {
  String _emailErrorText;
  String _passErrorText;

  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);

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
                errorText: _emailErrorText,
              ),
              keyboardType: TextInputType.emailAddress,
              onEditingComplete: () => node.nextFocus(),
              controller: _email,
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
                _submit();
              },
              controller: _pass,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Sign In'),
          onPressed: () => _submit(),
        ),
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
      ],
    );
  }

  Future<void> _submit() async {
    // Clear previous error while waiting for auth
    setState(() {
      _emailErrorText = null;
      _passErrorText = null;
    });

    String errorCode =
        await widget.onSubmitAuth(EmailAuthDetails(_email.text, _pass.text));
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
        _emailErrorText = 'Required';
        return;

      case 'empty-pass':
        _passErrorText = 'Required';
        return;
    }

    // Close dialog if there were no errors
    Navigator.of(context).pop();
  }
}
