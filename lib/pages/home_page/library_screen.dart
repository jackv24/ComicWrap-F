import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/system/database.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:comicwrap_f/widgets/scaffold_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
                onPressed: () {})
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

          var data = snapshot.data.data();
          List<dynamic> comicPaths = data['library'];

          if (comicPaths == null) return Text('User has no library!');

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 0.57,
            ),
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            itemCount: comicPaths.length,
            itemBuilder: (context, index) {
              final comic = comicPaths[index];
              Widget comicWidget;
              try {
                comicWidget =
                    ComicInfoCard((comic as DocumentReference).snapshots());
              } catch (e) {
                comicWidget = Text('ERROR: ${e.toString()}');
              }
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 3,
                duration: Duration(milliseconds: 200),
                delay: Duration(milliseconds: 100),
                child: ScaleAnimation(
                  scale: 0.85,
                  child: FadeInAnimation(
                    child: comicWidget,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
