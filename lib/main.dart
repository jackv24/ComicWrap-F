import 'package:appwrite/appwrite.dart';
import 'package:comicwrap_f/environment_config.dart';
import 'package:comicwrap_f/pages/library_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  late Client client;
  late Future<Response<dynamic>> _getUserAccount;

  @override
  void initState() {
    // Connect to server
    client = Client();
    client
        .setEndpoint(EnvironmentConfig.apiEndpoint)
        .setProject(EnvironmentConfig.apiProjectId)
        .setSelfSigned();

    final account = Account(client);
    _getUserAccount = account.createAnonymousSession();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Sign in flow
    return FutureBuilder(
      future: _getUserAccount,
      builder: (context, snapshot) {
        Widget homeWidget;

        // Still signing in
        if (snapshot.connectionState != ConnectionState.done) {
          if (snapshot.hasError) {
            homeWidget = _getScaffold(Text('Sign in error :('));
          } else {
            homeWidget = _getScaffold(Text('Signing in...'));
          }
        } else {
          homeWidget = LibraryScreen(
            client: client,
          );
        }

        // Sign in complete, display full app
        return MaterialApp(
          title: 'ComicWrap',
          theme: ThemeData(
            primarySwatch: Colors.pink,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: homeWidget,
        );
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
}
