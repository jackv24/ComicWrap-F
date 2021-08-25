import 'package:comicwrap_f/pages/library/library_screen.dart';
import 'package:comicwrap_f/utils/database.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // Setup global style for loading blocker
    EasyLoading.instance
      ..userInteractions = false
      ..maskType = EasyLoadingMaskType.black;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComicWrap',
      theme: ThemeData(
        primaryColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Firebase init
      home: Consumer(
        builder: (context, watch, child) {
          final asyncApp = watch(firebaseProvider);
          return asyncApp.when(
            loading: () => _loadingScreen('Initializing Firebase...'),
            error: (err, stack) =>
                _loadingScreen('Failed to initialize Firebase.'),
            // User auth
            data: (app) => Consumer(
              builder: (context, watch, child) {
                final asyncUserDoc = watch(userDocChangesProvider);
                return asyncUserDoc.when(
                  loading: () => _loadingScreen('Signing in...'),
                  error: (err, stack) => _loadingScreen('Error signing in'),
                  data: (user) => LibraryScreen(),
                );
              },
            ),
          );
        },
      ),
      builder: EasyLoading.init(),
    );
  }

  Widget _loadingScreen(String infoText) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(),
          ),
          Text(
            infoText,
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ],
      ),
    );
  }
}
