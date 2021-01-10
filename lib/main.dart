import 'package:flutter/material.dart';
import 'package:ms_material_color/ms_material_color.dart';

import 'home_page/home_page.dart';

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
          primarySwatch: MsMaterialColor(0xffe91e63),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomePage());
  }
}
