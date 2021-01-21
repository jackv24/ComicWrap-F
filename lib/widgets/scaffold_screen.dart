import 'package:flutter/material.dart';

abstract class ScaffoldScreen implements Widget {
  String get title;
  List<Widget> getActions(BuildContext context);
}
