import 'package:flutter/material.dart';

import 'library_screen.dart';
import 'settings_screen.dart';
import 'updates_screen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedScreen = 0;

  final _screenOptions = [
    LibraryScreen(),
    UpdatesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ComicWrap"),
        actions: [
          IconButton(
              icon: Icon(
                Icons.library_add,
                color: Theme.of(context).primaryIconTheme.color,
              ),
              onPressed: null)
        ],
      ),
      body: _screenOptions[selectedScreen],
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
        currentIndex: selectedScreen,
        onTap: (index) {
          setState(() {
            selectedScreen = index;
          });
        },
        showUnselectedLabels: true,
        selectedItemColor: Theme.of(context).accentColor,
        unselectedItemColor: Theme.of(context).disabledColor,
      ),
    );
  }
}
