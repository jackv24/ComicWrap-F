import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    // Sign-in UI
    final asyncUser = watch(userChangesProvider);
    final userAuthWidget = asyncUser.when(
      loading: () => Text('Waiting for sign in...'),
      error: (err, stack) => Text('Error signing in.'),
      data: (user) {
        if (user == null) {
          return Text(
              'User is null - there should always be a user, even if anonymous!');
        } else if (user.isAnonymous) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text("You're an anonymous user. "
                    "Sign in to make sure you don't lose your data!"),
              ),
              SignInButton(Buttons.Email, onPressed: () {
                linkEmailAuth(context);
              }),
              SignInButton(Buttons.Google, onPressed: () {
                linkGoogleAuth(context);
              }),
            ],
          );
        } else {
          return Text("You're signed in as a full user!");
        }
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
