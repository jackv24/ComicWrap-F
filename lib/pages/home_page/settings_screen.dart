import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:comicwrap_f/system/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Stream<User?> _authStream;

  @override
  void initState() {
    _authStream = getAuthStream();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HomePageScreen(
      title: Text('Settings'),
      bodySliver: SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate.fixed([
            // Sign-in UI
            StreamBuilder<User?>(
              stream: _authStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  var user = snapshot.data;
                  if (user == null) {
                    return Text('Waiting for sign in...');
                  } else {
                    if (user.isAnonymous) {
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text("You're an anonymous user. "
                                "Sign in to make sure you don't lose your data!"),
                          ),
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
          ]),
        ),
      ),
    );
  }
}
