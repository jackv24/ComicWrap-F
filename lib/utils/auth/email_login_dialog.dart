import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  errorText: _emailErrorText,
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
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
