import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/pages/comic_page.dart';
import 'package:flutter/material.dart';

class ComicInfoCard extends StatelessWidget {
  final Stream<DocumentSnapshot> docStream;

  const ComicInfoCard(this.docStream, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading...");
        }

        var data = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 8.5 / 11.0,
              child: Material(
                color: Colors.grey,
                elevation: 5.0,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ComicPage(),
                    ));
                  },
                  child: Image.network(
                    data['coverImageUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 5.0),
            Text(
              data['name'] ?? '!!!null name!!!',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            SizedBox(height: 2.0),
            Text(
              '3 days ago',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.subtitle2,
            ),
          ],
        );
      },
    );
  }
}
