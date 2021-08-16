import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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
        final String userHintText;
        final List<Widget> signInWidgets;
        if (user == null) {
          userHintText = 'Not signed in. Please sign in below:';
          signInWidgets = [
            SignInButton(Buttons.Email,
                onPressed: () => linkEmailAuth(context)),
            SignInButton(Buttons.Google,
                onPressed: () => _futureBlocked(linkGoogleAuth(context))),
          ];
        } else {
          userHintText = 'You\'re signed in as a full user!';
          signInWidgets = [
            TextButton(
              onPressed: () => _futureBlocked(signOut(context)),
              child: Text('Sign Out'),
            ),
          ];
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(userHintText),
            ),
            ...signInWidgets,
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

  Future<void> _futureBlocked(Future future) async {
    EasyLoading.show();
    await future;
    EasyLoading.dismiss();
  }
}
