import 'package:comicwrap_f/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeleteAccountDialogue extends StatefulWidget {
  const DeleteAccountDialogue({Key? key}) : super(key: key);

  @override
  _DeleteAccountDialogueState createState() => _DeleteAccountDialogueState();
}

class _DeleteAccountDialogueState extends State<DeleteAccountDialogue> {
  final TextEditingController _passwordController = TextEditingController();

  bool _canDelete = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(() {
      setState(() {
        _canDelete = _passwordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(loc.settingsDeleteAccount),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(loc.deleteAccountConfirm),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.signInPassword,
                helperText: loc.deleteAccountPasswordHelper,
                errorText: _errorText,
              ),
              obscureText: true,
              controller: _passwordController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(loc.cancel),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          child: Text(loc.settingsDeleteAccount),
          style: TextButton.styleFrom(
            primary: Colors.red,
          ),
          onPressed: _canDelete
              ? () async {
                  final errorCode =
                      await deleteAccount(context, _passwordController.text);
                  if (errorCode == null) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() {
                      _errorText = _getErrorText(errorCode, loc);
                    });
                  }
                }
              : null,
        ),
      ],
    );
  }

  String _getErrorText(String errorCode, AppLocalizations loc) {
    switch (errorCode) {
      case 'wrong-password':
        return loc.errorWrongPass;
      default:
        return errorCode;
    }
  }
}