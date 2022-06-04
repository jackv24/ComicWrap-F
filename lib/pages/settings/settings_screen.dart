import 'package:comicwrap_f/pages/main_page_inner.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/pages/settings/delete_account_dialog.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/settings.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return MainPageScaffold(
      title: loc.settingsTitle,
      bodySlivers: [
        MainPageInner(
          sliver: SliverPadding(
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                InputDecorator(
                  decoration:
                      InputDecoration(label: Text(loc.settingsThemeLabel)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Consumer(builder: (context, ref, child) {
                        final currentTheme = ref.watch(themeModeProvider);
                        const borderWidth = 1.0;
                        return ToggleButtons(
                          borderWidth: borderWidth,
                          constraints: BoxConstraints.expand(
                            width: (constraints.maxWidth - borderWidth * 2) /
                                    ThemeMode.values.length -
                                borderWidth * 2,
                            height: 48.0,
                          ),
                          isSelected: ThemeMode.values
                              .map((val) => currentTheme == val)
                              .toList(),
                          onPressed: (index) => ref
                              .read(themeModeProvider.notifier)
                              .setValue(ThemeMode.values[index]),
                          children: ThemeMode.values
                              .map((val) => TextButton.icon(
                                    onPressed: null,
                                    icon: Icon(_getThemeModeIcon(val)),
                                    label: Text(_getThemeModeName(val, loc)),
                                  ))
                              .toList(),
                        );
                      });
                    },
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final didDeleteAccount = await showDialog(
                      context: context,
                      builder: (context) {
                        return const DeleteAccountDialogue();
                      },
                    ) as bool?;
                    if (didDeleteAccount ?? false) Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    primary: Colors.red,
                  ),
                  child: Text(loc.settingsDeleteAccount),
                ),
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
        )
      ],
    );
  }

  IconData? _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_4;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String _getThemeModeName(ThemeMode mode, AppLocalizations loc) {
    switch (mode) {
      case ThemeMode.system:
        return loc.settingsThemeModeSystem;
      case ThemeMode.light:
        return loc.settingsThemeModeLight;
      case ThemeMode.dark:
        return loc.settingsThemeModeDark;
    }
  }
}
