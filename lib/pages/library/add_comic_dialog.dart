import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddComicDialog extends StatefulWidget {
  const AddComicDialog({Key? key}) : super(key: key);

  @override
  _AddComicDialogState createState() => _AddComicDialogState();
}

class _AddComicDialogState extends State<AddComicDialog> {
  String? _urlErrorText;
  final _url = TextEditingController();

  bool _preventPop = false;

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);
    final loc = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async => !_preventPop,
      child: AlertDialog(
        title: Text(loc.addComicTitle),
        content: SingleChildScrollView(
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.web),
              labelText: loc.addComicUrl,
              hintText: 'http://www.example.com/',
              errorText: _urlErrorText,
            ),
            keyboardType: TextInputType.url,
            onEditingComplete: () => node.nextFocus(),
            controller: _url,
            enabled: !_preventPop,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(loc.addComicCancelButton),
            onPressed:
                _preventPop ? null : () => Navigator.of(context).pop(null),
          ),
          TextButton(
            child: Text(loc.addComicAddButton),
            onPressed: _preventPop ? null : () => _submit(context),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    // Clear previous error while waiting
    setState(() {
      _urlErrorText = null;
      _preventPop = true;
    });

    final functions =
        ProviderScope.containerOf(context).read(functionsProvider);
    if (functions == null) {
      setState(() {
        _urlErrorText = 'Error: could not get instance of FirebaseFunctions.';
        _preventPop = false;
      });
      return;
    }

    final callable = functions.httpsCallable('addUserComic');

    try {
      final HttpsCallableResult<dynamic> result = await callable(_url.text);
      print('Returned result: ' + result.data);
    } on FirebaseFunctionsException catch (e) {
      print('Caught error: ' + e.code);
      setState(() {
        _urlErrorText = e.message;
        _preventPop = false;
      });

      return;
    }

    setState(() {
      _preventPop = false;
    });

    // Close dialog if there were no errors
    Navigator.of(context).pop();
  }
}
