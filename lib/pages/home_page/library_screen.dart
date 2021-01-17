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
      StreamBuilder<DocumentSnapshot>(
        stream: getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error reading user stream');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading user data...");
          }

          List<dynamic> comicPaths = snapshot.data.get('library');

          return GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.57,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            children: comicPaths.map((comic) {
              if (comic is DocumentReference)
                return ComicInfoCard(comic.snapshots());
              else
                return Text('ERROR: $comic is not a DocumentReference');
            }).toList(),
          );
        },
      ),
    );
  }
}
