import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasResetPassword = false;

  @override
  Widget build(BuildContext context) {
    return MainPageScaffold(
      title: 'Settings',
      bodySliver: SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate.fixed([
            TextButton(
              onPressed: () async {
                await signOut(context);
                Navigator.of(context).pop();
              },
              child: const Text('Sign Out'),
            ),
            Consumer(builder: (context, ref, child) {
              final auth = ref
                  .watch(authProvider)
                  .maybeWhen(data: (auth) => auth, orElse: () => null);
              final user = ref
                  .watch(userChangesProvider)
                  .maybeWhen(data: (value) => value, orElse: () => null);

              final bool canResetPassword;
              if (auth == null || user == null) {
                canResetPassword = false;
              } else {
                canResetPassword = user.providerData
                    .any((element) => element.providerId == 'password');
              }

              return TextButton(
                onPressed: !canResetPassword || _hasResetPassword
                    ? null
                    : () async {
                        EasyLoading.show();
                        if (user!.email != null) {
                          await auth!
                              .sendPasswordResetEmail(email: user.email!);
                        }
                        EasyLoading.dismiss();
                        setState(() {
                          _hasResetPassword = true;
                        });
                      },
                child: const Text('Reset Password'),
              );
            }),
            const Divider(),
            const GitHubLinkButton(),
          ]),
        ),
      ),
    );
  }
}
