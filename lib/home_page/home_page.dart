import 'package:comicwrap_f/scaffold_screen.dart';
import 'package:flutter/material.dart';

import 'library_screen.dart';
import 'settings_screen.dart';
import 'updates_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedScreenIndex = 0;

  @override
  Widget build(BuildContext context) {
    var selectedScreen = _getScreenOption(context, selectedScreenIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text("ComicWrap"),
        actions: selectedScreen.actions,
      ),
      body: selectedScreen,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(Icons.collections_bookmark),
          ),
          BottomNavigationBarItem(
            label: 'Updates',
            icon: Icon(Icons.new_releases),
          ),
          BottomNavigationBarItem(
            label: 'Settings',
            icon: Icon(Icons.settings),
          ),
        ],
        currentIndex: selectedScreenIndex,
        onTap: (index) {
          setState(() {
            selectedScreenIndex = index;
          });
        },
        showUnselectedLabels: true,
        selectedItemColor: Theme.of(context).accentColor,
        unselectedItemColor: Theme.of(context).disabledColor,
      ),
    );
  }

  ScaffoldScreen _getScreenOption(BuildContext context, int index) {
    switch (index) {
      case 0:
        return LibraryScreen(context);

      case 1:
        return UpdatesScreen();

      case 2:
        return SettingsScreen();

      default:
        throw RangeError.value(index);
    }
  }
}
