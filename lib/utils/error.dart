import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showErrorDialog(BuildContext context, String error) {
  final loc = AppLocalizations.of(context)!;

  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(children: [
            const Padding(
              padding: EdgeInsets.only(right: 4.0),
              child: Icon(Icons.error, color: Colors.red),
            ),
            Text(loc.errorTitle),
          ]),
          content: Text(error),
          actions: [
            TextButton(
              child: Text(loc.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      });
}
