import 'package:flutter/material.dart';

import 'library_screen.dart';
import 'settings_screen.dart';
import 'updates_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedScreenIndex = 0;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedScreenIndex,
        children: [
          LibraryScreen(),
          UpdatesScreen(),
          SettingsScreen(),
        ],
      ),
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
        currentIndex: _selectedScreenIndex,
        onTap: (index) {
          setState(() {
            _selectedScreenIndex = index;
          });
        },
        showUnselectedLabels: true,
        selectedItemColor: theme.accentColor,
        unselectedItemColor: theme.disabledColor,
      ),
    );
  }
}
