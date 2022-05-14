import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void initState() {
    super.initState();

    // Auto-fill URL field with clipboard text
    Clipboard.getData('text/plain').then((data) {
      final text = data?.text;
      if (text == null || text.isEmpty) return;

      // Only auto-fill if clipboard text is a URL
      if (!text.startsWith('http://') && !text.startsWith('https://')) return;

      _url.text = text;
      _url.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);
    final loc = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async => !_preventPop,
      child: AlertDialog(
        title: Text(loc.addComicTitle),
        content: SingleChildScrollView(
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.web),
              labelText: loc.addComicUrl,
              hintText: 'https://www.example.com/',
              errorText: _urlErrorText,
            ),
            keyboardType: TextInputType.url,
            onEditingComplete: () => node.nextFocus(),
            controller: _url,
            enabled: !_preventPop,
            autofocus: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed:
                _preventPop ? null : () => Navigator.of(context).pop(null),
            child: Text(loc.addComicCancelButton),
          ),
          TextButton(
            onPressed: _preventPop ? null : () => _submit(context),
            child: Text(loc.addComicAddButton),
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
      print('Caught error: ${e.code}');
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
