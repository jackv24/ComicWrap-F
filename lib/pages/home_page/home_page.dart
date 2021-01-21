import 'package:comicwrap_f/widgets/scaffold_screen.dart';
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
    var selectedScreen = _getScreenOption(selectedScreenIndex);

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedScreen.title,
        ),
        actions: selectedScreen.getActions(context),
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
        selectedItemColor: theme.accentColor,
        unselectedItemColor: theme.disabledColor,
      ),
    );
  }

  ScaffoldScreen _getScreenOption(int index) {
    switch (index) {
      case 0:
        return LibraryScreen();

      case 1:
        return UpdatesScreen();

      case 2:
        return SettingsScreen();

      default:
        throw RangeError.value(index);
    }
  }
}
