import 'package:comicwrap_f/system/auth.dart';
import 'package:comicwrap_f/widgets/scaffold_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SettingsScreen extends StatelessWidget implements ScaffoldScreen {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      child: ListView(
        children: [
          // Sign-in UI
          StreamBuilder<User>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                var user = snapshot.data;
                if (user == null) {
                  return Text('Waiting for sign in...');
                } else {
                  if (user.isAnonymous) {
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        Text("You're an anonymous user. "
                            "Sign in to make sure you don't lose your data!"),
                        SignInButton(Buttons.Email, onPressed: () {
                          linkEmailAuth(context);
                        }),
                        SignInButton(Buttons.Google, onPressed: () {
                          linkGoogleAuth(context);
                        }),
                      ],
                    );
                  } else {
                    return Text("You're signed in as a full user!");
                  }
                }
              } else {
                return Text('Waiting for auth connection...');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  String get title => 'Settings';

  @override
  List<Widget> getActions(BuildContext context) {
    return [];
  }
}
