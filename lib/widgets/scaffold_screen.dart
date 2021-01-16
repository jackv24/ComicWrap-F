import 'package:flutter/material.dart';

abstract class ScaffoldScreen extends StatelessWidget {
  final List<Widget> actions;
  final String title;

  ScaffoldScreen(this.title, {Key key})
      : actions = [],
        super(key: key);

  const ScaffoldScreen.actions(this.title, this.actions, {Key key})
      : super(key: key);
}
