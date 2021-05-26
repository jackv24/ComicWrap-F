import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:comicwrap_f/pages/home_page/home_page.dart';
import 'package:comicwrap_f/system/auth.dart';
import 'package:comicwrap_f/system/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/subjects.dart';

const bool USE_EMULATORS = bool.fromEnvironment('USE_EMULATORS');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _homePageKey = GlobalKey();
  late BehaviorSubject<User?> _authSubject;
  Future<void>? _startAuth;

  @override
  void initState() {
    _authSubject = BehaviorSubject<User?>();

    // Wait for firebase to initialise
    firebaseInit!.then((firebaseApp) {
      // Setup connection to emulators if desired
      if (USE_EMULATORS) {
        String host = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';

        FirebaseFirestore.instance.settings =
            Settings(host: host + ':8080', sslEnabled: false);
        FirebaseFunctions.instance
            .useFunctionsEmulator(origin: 'http://$host:5001');
      }

      // Start listening to auth changes here (build shouldn't have side effects)
      FirebaseAuth.instance.authStateChanges().listen((user) {
        // If user is not authenticated, authenticate them
        if (user == null && !isChangingAuth && _startAuth == null) {
          _startAuth = startAuth();
        }

        // Re-emit event for StreamBuilder
        _authSubject.add(user);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Firebase init state
    return FutureBuilder(
      future: firebaseInit,
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
          homeWidget = StreamBuilder<User?>(
            stream: _authSubject.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                var user = snapshot.data;
                if (user == null) {
                  // Firebase sign in state
                  return FutureBuilder(
                    future: _startAuth,
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
              primaryColor: Colors.white,
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
