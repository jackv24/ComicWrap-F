import 'package:comicwrap_f/pages/library_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:appwrite/appwrite.dart';

const String API_ENDPOINT = String.fromEnvironment('COMICWRAPF_API_ENDPOINT');
const String API_PROJECTID = String.fromEnvironment('COMICWRAPF_API_PROJECTID');

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
  late Future<Response<dynamic>> _getUserAccount;

  @override
  void initState() {
    // Connect to server
    final client = Client();
    client.setEndpoint(API_ENDPOINT).setProject(API_PROJECTID).setSelfSigned();

    final account = Account(client);
    _getUserAccount = account.get();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Sign in flow
    return FutureBuilder(
      future: _getUserAccount,
      builder: (context, snapshot) {
        // Still signing in
        if (snapshot.connectionState != ConnectionState.done) {
          if (snapshot.hasError) {
            return _getScaffold(Text('Sign in error :('));
          } else {
            return _getScaffold(Text('Signing in...'));
          }
        }

        // Sign in complete, display full app
        return MaterialApp(
            title: 'ComicWrap',
            theme: ThemeData(
              primarySwatch: Colors.pink,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: LibraryScreen());
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
