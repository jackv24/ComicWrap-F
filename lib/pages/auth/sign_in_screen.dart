import 'package:comicwrap_f/pages/auth/sign_up_screen.dart';
import 'package:comicwrap_f/pages/main_page_inner.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _emailErrorText;
  String? _passErrorText;

  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _inProgress = false;
  bool _hasSentPassReset = false;

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);

    return MainPageScaffold(
      title: 'Sign In',
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
                  errorText: _passErrorText,
                ),
                obscureText: true,
                onSubmitted: (_) {
                  node.unfocus();
                  _submit(context);
                },
                controller: _pass,
                enabled: !_inProgress,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: const Text('Sign In'),
                        onPressed: _inProgress ? null : () => _submit(context),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: AbsorbPointer(
                        absorbing: _inProgress,
                        child:
                            SignInButton(Buttons.Google, onPressed: () async {
                          setState(() {
                            _inProgress = true;
                          });
                          await linkGoogleAuth(context);
                          setState(() {
                            _inProgress = false;
                          });
                        }),
                      ),
                    ),
                    TextButton(
                      child: const Text('Sign Up with Email'),
                      onPressed:
                          _inProgress ? null : () => _onSignUpPressed(context),
                    ),
                    // Password reset button
                    Consumer(builder: (context, ref, child) {
                      final auth = ref
                          .watch(authProvider)
                          .maybeWhen(data: (auth) => auth, orElse: () => null);
                      return TextButton(
                        onPressed:
                            _inProgress || auth == null || _hasSentPassReset
                                ? null
                                : () => _onResetPasswordPressed(context, auth),
                        child: const Text('Reset Password'),
                      );
                    })
                  ],
                ),
              ),
              const Divider(),
              const GitHubLinkButton(),
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
      _passErrorText = null;
      _inProgress = true;
    });

    final errorCode = await submitSignIn(
        context, EmailSignInDetails(_email.text, _pass.text));
    _showErrorCode(errorCode);

    setState(() {
      _inProgress = false;
    });
  }

  void _showErrorCode(String? errorCode) {
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

      case 'invalid-email':
        setState(() {
          _emailErrorText = 'Email is invalid';
        });
        break;

      case null:
        // Do nothing if there were no errors
        // App state management will handle switching screens
        break;

      default:
        // Unhandled error, just show code
        setState(() {
          _emailErrorText = errorCode;
        });
        break;
    }
  }

  Future<void> _onSignUpPressed(BuildContext context) async {
    await Navigator.push(context, CupertinoPageRoute(
      builder: (context) {
        return SignUpScreen(
          initialEmail: _email.text,
          initialPassword: _pass.text,
        );
      },
    ));
  }

  Future<void> _onResetPasswordPressed(
      BuildContext context, FirebaseAuth auth) async {
    setState(() {
      _emailErrorText = null;
      _passErrorText = null;
    });

    if (_email.text.isEmpty) {
      _showErrorCode('empty-email');
      return;
    }

    final response = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reset Password?'),
            content: Text(
                'Are you sure you want to reset the password for ${_email.text}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reset Password'),
              ),
            ],
          );
        });

    if (response != true) {
      return;
    }

    setState(() {
      _inProgress = true;
    });

    try {
      await auth.sendPasswordResetEmail(email: _email.text);
    } on FirebaseAuthException catch (exception, _) {
      setState(() {
        _inProgress = false;
      });
      _showErrorCode(exception.code);
      return;
    }

    setState(() {
      _inProgress = false;
      _hasSentPassReset = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')));
  }
}
