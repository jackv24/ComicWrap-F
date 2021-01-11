import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ms_material_color/ms_material_color.dart';

import 'home_page/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    // Handle UI state for Firebase init Future
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        Widget homeWidget;
        if (snapshot.connectionState != ConnectionState.done) {
          // Show messages for initializing Firebase
          Widget body;
          if (snapshot.hasError) {
            body = Text("Failed to initialize Firebase.");
          } else {
            body = Text("Initializing Firebase...");
          }

          // Display messages in a scaffold for styling
          homeWidget = Scaffold(
            appBar: AppBar(
              title: Text("ComicWrap"),
            ),
            body: body,
          );
        } else {
          // Init succeeded, display full page
          homeWidget = HomePage();

          // Listen for auth changes - not sure if it should go here?
          FirebaseAuth.instance.authStateChanges().listen((User user) {
            if (user == null) {
              print('User is currently signed out!');
              // TODO: Sign user in anonymously, display indicator on settings for proper sign in
            } else {
              print('User is signed in!');
            }
          });
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
}
