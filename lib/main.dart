import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:comicwrap_f/pages/home_page/home_page.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ms_material_color/ms_material_color.dart';

const bool USE_EMULATORS = bool.fromEnvironment('USE_EMULATORS');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  final _homePageKey = GlobalKey();

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
          if (USE_EMULATORS) {
            String host = defaultTargetPlatform == TargetPlatform.android
                ? '10.0.2.2'
                : 'localhost';

            FirebaseFirestore.instance.settings =
                Settings(host: host + ':8080', sslEnabled: false);
            FirebaseFunctions.instance
                .useFunctionsEmulator(origin: 'http://$host:5001');
          }

          // Firebase auth state
          homeWidget = StreamBuilder<User>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                var user = snapshot.data;
                // Only create new anonymous user if we're not changing auth elsewhere
                if (user == null && !isChangingAuth) {
                  // Firebase sign in state
                  return FutureBuilder(
                    future: startAuth(),
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
                  return HomePage(key: _homePageKey);
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
    return Stack(
      children: [
        HomePage(key: _homePageKey),
        Scaffold(
          appBar: AppBar(
            title: Text("ComicWrap"),
          ),
          body: body,
        ),
      ],
    );
  }
}
