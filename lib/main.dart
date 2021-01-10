import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ComicWrap',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text("ComicWrap"),
            actions: [
              IconButton(
                  icon: Icon(
                    Icons.library_add,
                    color: Theme.of(context).primaryIconTheme.color,
                  ),
                  onPressed: null
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: [
                Text("Test")
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                label: 'Library',
                icon: Icon(Icons.collections_bookmark),
              ),
              BottomNavigationBarItem(
                label: 'Reading',
                icon: Icon(Icons.history),
              ),
              BottomNavigationBarItem(
                label: 'Settings',
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        )
    );
  }
}

Future<void> _onRefresh() async {
  await Future.delayed(Duration(seconds: 2));
}
