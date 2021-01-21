import 'package:comicwrap_f/widgets/scaffold_screen.dart';
import 'package:flutter/material.dart';

class UpdatesScreen extends StatelessWidget implements ScaffoldScreen {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      child: ListView(
        children: [],
      ),
    );
  }

  @override
  String get title => 'Updates';

  @override
  List<Widget> getActions(BuildContext context) {
    return [];
  }
}
