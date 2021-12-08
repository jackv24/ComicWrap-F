import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GitHubLinkButton extends StatelessWidget {
  const GitHubLinkButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          loc.githubLinkPrompt,
          style: theme.textTheme.caption,
        ),
        TextButton.icon(
          icon: const Icon(Icons.open_in_browser),
          label: Text(loc.githubLinkLabel),
          onPressed: () => launch('https://github.com/jackv24/ComicWrap-F/'),
        ),
      ],
    );
  }
}
