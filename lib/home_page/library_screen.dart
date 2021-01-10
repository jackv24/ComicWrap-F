import 'package:comicwrap_f/scaffold_screen.dart';
import 'package:flutter/material.dart';

import 'home_screen_container.dart';

class LibraryScreen extends ScaffoldScreen {
  LibraryScreen(BuildContext context)
      : super.actions([
          IconButton(
              icon: Icon(
                Icons.library_add,
                color: Theme.of(context).primaryIconTheme.color,
              ),
              onPressed: null)
        ]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      child: HomeScreenContainer(ListView(
        children: [
          Text(
            'Last Read',
            style: Theme.of(context).textTheme.headline6,
          )
        ],
      )),
    );
  }
}
