import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainPageScaffold(
      title: 'Settings',
      bodySliver: SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate.fixed([
            TextButton(
              onPressed: () async {
                await signOut(context);
                Navigator.of(context).pop();
              },
              child: Text('Sign Out'),
            ),
            Divider(),
            GitHubLinkButton(),
          ]),
        ),
      ),
    );
  }
}
