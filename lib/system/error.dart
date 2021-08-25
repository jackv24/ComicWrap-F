import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String error) {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(children: [
            Padding(
              padding: EdgeInsets.only(right: 4.0),
              child: Icon(Icons.error, color: Colors.red),
            ),
            Text('Error'),
          ]),
          content: Text(error),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      });
}
