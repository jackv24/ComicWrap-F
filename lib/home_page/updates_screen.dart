import 'package:comicwrap_f/scaffold_screen.dart';
import 'package:flutter/material.dart';

import 'home_screen_container.dart';

class UpdatesScreen extends ScaffoldScreen {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      child: HomeScreenContainer(ListView(
        children: [],
      )),
    );
  }
}
