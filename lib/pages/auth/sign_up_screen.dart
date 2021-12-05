import 'package:comicwrap_f/pages/main_page_inner.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;

  const SignUpScreen({Key? key, this.initialEmail, this.initialPassword})
      : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? _emailErrorText;
  String? _passAErrorText;
  String? _passBErrorText;

  late final TextEditingController _email;
  late final TextEditingController _passA;
  final _passB = TextEditingController();

  bool _inProgress = false;

  @override
  void initState() {
    super.initState();

    _email = TextEditingController(text: widget.initialEmail);
    _passA = TextEditingController(text: widget.initialPassword);
  }

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);

    return MainPageScaffold(
      title: 'Email Sign Up',
      bodySliver: MainPageInner(
        sliver: SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  errorText: _emailErrorText,
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onEditingComplete: () => node.nextFocus(),
                controller: _email,
                enabled: !_inProgress,
              ),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.security),
                  labelText: 'Password',
                  errorText: _passAErrorText,
                ),
                obscureText: true,
                onEditingComplete: () => node.nextFocus(),
                controller: _passA,
                enabled: !_inProgress,
              ),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.security),
                  labelText: 'Confirm Password',
                  errorText: _passBErrorText,
                ),
                obscureText: true,
                onSubmitted: (_) {
                  node.unfocus();
                  _submit(context);
                },
                controller: _passB,
                enabled: !_inProgress,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Sign Up'),
                    onPressed: _inProgress ? null : () => _submit(context),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    // Clear previous error while waiting for auth
    setState(() {
      _emailErrorText = null;
      _passAErrorText = null;
      _passBErrorText = null;
      _inProgress = true;
    });

    final errorCode = await submitSignUp(
        context, EmailSignUpDetails(_email.text, _passA.text, _passB.text));

    setState(() {
      _inProgress = false;
    });

    switch (errorCode) {
      case 'empty-auth':
        setState(() {
          _emailErrorText = 'Required';
          _passAErrorText = 'Required';
        });
        break;

      case 'empty-email':
        setState(() {
          _emailErrorText = 'Required';
        });
        break;

      case 'empty-pass':
        setState(() {
          _passAErrorText = 'Required';
        });
        break;

      case 'pass-not-match':
        setState(() {
          _passBErrorText = 'Does not match';
        });
        break;

      case null:
      // No errors, account create succeeded!
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
