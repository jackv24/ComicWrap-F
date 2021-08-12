import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/pages/home_page/library_screen.dart';
import 'package:comicwrap_f/system/database.dart';
import 'package:comicwrap_f/system/firebase.dart';
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
  final _homePageKey = GlobalKey();

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
            loading: () => _getScaffold(Text('Initializing Firebase...')),
            error: (err, stack) =>
                _getScaffold(Text('Failed to initialize Firebase.')),
            // User auth
            data: (app) => Consumer(
              builder: (context, watch, child) {
                final asyncUser = watch(userDocChangesProvider);
                return asyncUser.when(
                  loading: () => _getScaffold(Text('Signing in...')),
                  error: (err, stack) => _getScaffold(Text('Error signing in')),
                  data: (user) => LibraryScreen(key: _homePageKey),
                );
              },
            ),
          );
        },
      ),
      builder: EasyLoading.init(),
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
