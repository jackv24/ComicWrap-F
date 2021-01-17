import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/system/database.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:comicwrap_f/widgets/scaffold_screen.dart';
import 'package:flutter/material.dart';

import 'home_screen_container.dart';

class LibraryScreen extends ScaffoldScreen {
  LibraryScreen(BuildContext context)
      : super.actions(
          'Library',
          [
            IconButton(
                icon: Icon(
                  Icons.library_add,
                  color: Theme.of(context).primaryIconTheme.color,
                ),
                onPressed: null)
          ],
        );

  @override
  Widget build(BuildContext context) {
    return HomeScreenContainer(
      StreamBuilder<QuerySnapshot>(
        stream: getComicsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error reading comics stream');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading comics...");
          }

          return GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.57,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            children: snapshot.data.docs.map((doc) {
              return ComicInfoCard(doc);
            }).toList(),
          );
        },
      ),
    );
  }
}
