import 'package:comicwrap_f/pages/auth/sign_up_screen.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);

    return MainPageScaffold(
      title: 'Sign In',
      bodySliver: SliverPadding(
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
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
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
                    child: SignInButton(Buttons.Google, onPressed: () async {
                      setState(() {
                        _inProgress = true;
                      });
                      await linkGoogleAuth(context);
                      setState(() {
                        _inProgress = false;
                      });
                    }),
                  ),
                  TextButton(
                    child: const Text('Sign Up with Email'),
                    onPressed:
                        _inProgress ? null : () => _onSignUpPressed(context),
                  )
                ],
              ),
            ),
            const Divider(),
            const GitHubLinkButton(),
          ]),
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

    setState(() {
      _inProgress = false;
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
}
