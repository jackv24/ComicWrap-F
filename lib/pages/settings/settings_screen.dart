import 'package:comicwrap_f/pages/main_page_inner.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return MainPageScaffold(
      title: loc.settingsTitle,
      bodySliver: MainPageInner(
        sliver: SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              TextButton(
                onPressed: () async {
                  await signOut(context);
                  Navigator.of(context).pop();
                },
                child: Text(loc.signOut),
              ),
              const Divider(),
              const GitHubLinkButton(),
            ]),
          ),
        ),
      ),
    );
  }
}
