import 'package:comicwrap_f/scaffold_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends ScaffoldScreen {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      child: ElevatedButton(
        child: Text("Test Page"),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: Text('Test Page'),
                        ),
                      )));
        },
      ),
    );
  }
}
