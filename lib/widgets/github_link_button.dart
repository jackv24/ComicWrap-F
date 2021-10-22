import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubLinkButton extends StatelessWidget {
  const GitHubLinkButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          "Have an issue? Want to help out? Follow the link below!",
          style: theme.textTheme.caption,
        ),
        TextButton.icon(
          icon: Icon(Icons.open_in_browser),
          label: Text('ComicWrap GitHub'),
          onPressed: () => launch("https://github.com/jackv24/ComicWrap-F/"),
        ),
      ],
    );
  }
}
