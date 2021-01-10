import 'package:flutter/material.dart';

abstract class ScaffoldScreen extends StatelessWidget {
  final List<Widget> actions;

  ScaffoldScreen({Key key})
      : actions = [],
        super(key: key);

  const ScaffoldScreen.actions(this.actions, {Key key}) : super(key: key);
}
