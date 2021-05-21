import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool _isChangingAuth = false;
bool get isChangingAuth => _isChangingAuth;

class EmailAuthDetails {
  String email;
  String pass;

  EmailAuthDetails(this.email, this.pass);
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
                  _submit();
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
            onPressed: _preventPop ? null : () => _submit(),
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

  Future<void> _submit() async {
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

    // TODO: Swap out Firebase error codes for Appwrite
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
        // TODO:
        break;
    }

    // Close dialog if there were no errors
    Navigator.of(context).pop();
  }
}
