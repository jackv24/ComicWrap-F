import 'dart:io' show Platform;

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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);

    final brightness = Theme.of(context).brightness;

    late final googleButtonType =
        brightness == Brightness.dark ? Buttons.GoogleDark : Buttons.Google;
    late final appleButtonType =
        brightness == Brightness.dark ? Buttons.AppleDark : Buttons.Apple;

    return MainPageScaffold(
      title: loc.signInTitle,
      bodySliver: MainPageInner(
        sliver: SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: loc.signInEmail,
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
                  labelText: loc.signInPassword,
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
                        child: Text(loc.signInButton),
                        onPressed: _inProgress ? null : () => _submit(context),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: AbsorbPointer(
                        absorbing: _inProgress,
                        child:
                            SignInButton(googleButtonType, onPressed: () async {
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
                    if (Platform.isIOS)
                      SizedBox(
                        width: double.infinity,
                        child: AbsorbPointer(
                          absorbing: _inProgress,
                          child: SignInButton(appleButtonType,
                              onPressed: () async {
                            setState(() {
                              _inProgress = true;
                            });
                            await linkAppleAuth(context);
                            setState(() {
                              _inProgress = false;
                            });
                          }),
                        ),
                      ),
                    TextButton(
                      child: Text(loc.signUpEmailButton),
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
                        child: Text(loc.resetPassword),
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
    _showErrorCode(context, errorCode);

    setState(() {
      _inProgress = false;
    });
  }

  void _showErrorCode(BuildContext context, String? errorCode) {
    final loc = AppLocalizations.of(context);

    switch (errorCode) {
      case 'empty-auth':
        setState(() {
          _emailErrorText = loc.errorRequired;
          _passErrorText = loc.errorRequired;
        });
        break;

      case 'empty-email':
        setState(() {
          _emailErrorText = loc.errorRequired;
        });
        break;

      case 'empty-pass':
        setState(() {
          _passErrorText = loc.errorRequired;
        });
        break;

      case 'user-not-found':
        setState(() {
          _emailErrorText = loc.errorNoUser;
        });
        break;

      case 'wrong-password':
        setState(() {
          _passErrorText = loc.errorWrongPass;
        });
        break;

      case 'invalid-email':
        setState(() {
          _emailErrorText = loc.errorInvalidEmail;
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
      _showErrorCode(context, 'empty-email');
      return;
    }

    final loc = AppLocalizations.of(context);

    final response = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(loc.resetPassDialogTitle),
            content: Text(loc.resetPassDialogText(_email.text)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.resetPassword),
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
      _showErrorCode(context, exception.code);
      return;
    }

    setState(() {
      _inProgress = false;
      _hasSentPassReset = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.resetPassSent)));
  }
}
