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
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        Widget homeWidget;
        if (snapshot.connectionState == ConnectionState.done) {
          homeWidget = HomePage();
        } else {
          Widget body;
          if (snapshot.hasError) {
            body = Text("Failed to connect to Firebase.");
          } else {
            body = Text("Connecting to Firebase...");
          }

          homeWidget = Scaffold(
            appBar: AppBar(
              title: Text("ComicWrap"),
            ),
            body: body,
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
}
