import 'package:comicwrap_f/home_page/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ms_material_color/ms_material_color.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    // Firebase init state
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        Widget homeWidget;
        if (snapshot.connectionState != ConnectionState.done) {
          // Show messages for initializing Firebase
          if (snapshot.hasError) {
            homeWidget = _getScaffold(Text('Failed to initialize Firebase.'));
          } else {
            homeWidget = _getScaffold(Text('Initializing Firebase...'));
          }
        } else {
          // Firebase auth state
          homeWidget = StreamBuilder<User>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                var user = snapshot.data;
                if (user == null) {
                  // Firebase sign in state
                  return FutureBuilder(
                    future: _authSequence(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        if (snapshot.hasError) {
                          return _getScaffold(Text('Sign in error :('));
                        } else {
                          return _getScaffold(Text('Signing in...'));
                        }
                      } else {
                        return _getScaffold(Text('Sign in complete!'));
                      }
                    },
                  );
                } else {
                  return HomePage();
                }
              } else {
                return _getScaffold(Text('Waiting for auth connection...'));
              }
            },
          );
        }

        return MaterialApp(
            title: 'ComicWrap',
            theme: ThemeData(
              primarySwatch: MsMaterialColor(0xffe91e63),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: homeWidget);
      },
    );
  }

  Widget _getScaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ComicWrap"),
      ),
      body: body,
    );
  }

  Future _authSequence() async {
    await FirebaseAuth.instance.signInAnonymously();
  }
}
