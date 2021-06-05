import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/pages/home_page/library_screen.dart';
import 'package:comicwrap_f/system/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  late Stream<User?> _authStream;

  @override
  void initState() {
    _authStream = getAuthStream();

    // Setup global style for loading blocker
    EasyLoading.instance
      ..userInteractions = false
      ..maskType = EasyLoadingMaskType.black;

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
            stream: _authStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                var user = snapshot.data;
                if (user == null) {
                  // Firebase sign in state
                  return _getScaffold(Text('Signing in...'));
                } else {
                  return LibraryScreen(key: _homePageKey);
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
          home: homeWidget,
          builder: EasyLoading.init(),
        );
      },
    );
  }

  Widget _getScaffold(Widget body) {
    return Stack(
      children: [
        LibraryScreen(key: _homePageKey),
        HomePageScreen(
            title: Text("ComicWrap"),
            bodySliver: SliverToBoxAdapter(child: body)),
      ],
    );
  }
}
