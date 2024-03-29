import 'package:comicwrap_f/pages/main_page_inner.dart';
import 'package:comicwrap_f/pages/main_page_scaffold.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/widgets/github_link_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  bool _sentVerification = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return MainPageScaffold(
      title: 'Verify Email',
      bodySlivers: [
        MainPageInner(
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 20.0),
                child: Consumer(
                  builder: (context, ref, child) {
                    final user = ref
                        .watch(userChangesProvider)
                        .maybeWhen(data: (data) => data, orElse: () => null);

                    // Should never show screen when user is not signed in
                    if (user == null) return ErrorWidget('User is null');

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            loc.emailVerifyUserNull(user.email!),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sentVerification
                                ? null
                                : () => _sendVerification(user),
                            child: Text(loc.emailVerifySend),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Consumer(
                            builder: (context, ref, child) {
                              return ElevatedButton(
                                child: Text(loc.emailVerifyRefresh),
                                onPressed: () => _reloadUser(ref, user),
                              );
                            },
                          ),
                        ),
                        TextButton(
                          child: Text(loc.signOut),
                          onPressed: () => signOut(context),
                        )
                      ],
                    );
                  },
                ),
              ),
              const Divider(),
              const GitHubLinkButton(),
            ]),
          ),
        )
      ],
    );
  }

  Future<void> _sendVerification(User user) async {
    EasyLoading.show();
    await user.sendEmailVerification();
    EasyLoading.dismiss();

    setState(() {
      _sentVerification = true;
    });
  }

  Future<void> _reloadUser(WidgetRef ref, User user) async {
    EasyLoading.show();
    await user.reload();
    EasyLoading.dismiss();

    ref.refresh(userChangesProvider);
  }
}
