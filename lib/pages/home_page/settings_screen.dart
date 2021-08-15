import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final asyncUser = watch(userChangesProvider);

    // Sign-in UI
    final userAuthWidget = asyncUser.when(
      loading: () => Text('Waiting for sign in...'),
      error: (err, stack) => Text('Error signing in.'),
      data: (user) {
        final String? userHintText;
        if (user == null) {
          userHintText =
              'User is null - there should always be a user, even if anonymous!';
        } else if (user.isAnonymous) {
          userHintText =
              'You\'re an anonymous user. Sign in to make sure you don\'t lose your data!';
        } else {
          userHintText = 'You\'re signed in as a full user!';
        }

        final signInButtons = [
          SignInButton(Buttons.Email, onPressed: () {
            linkEmailAuth(context);
          }),
          SignInButton(Buttons.Google, onPressed: () {
            linkGoogleAuth(context);
          }),
        ];

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(userHintText),
            ),
            if (user == null || user.isAnonymous) ...signInButtons,
            if (user == null)
              ElevatedButton.icon(
                  onPressed: () {
                    signInAnon(context);
                  },
                  icon: Icon(Icons.person),
                  label: Text('Anonymous')),
            if (user != null)
              TextButton(
                onPressed: () {
                  signOut(context);
                },
                child: Text('Sign Out'),
              ),
          ],
        );
      },
    );

    return HomePageScreen(
      title: Text('Settings'),
      bodySliver: SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate.fixed([
            userAuthWidget,
          ]),
        ),
      ),
    );
  }
}
