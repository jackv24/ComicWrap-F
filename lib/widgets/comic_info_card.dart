import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/pages/comic_page.dart';
import 'package:flutter/material.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';

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

        var data = snapshot.data.data();
        String coverImageUrl = data['coverImageUrl'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 210.0 / 297.0,
              child: Material(
                color: Colors.white,
                elevation: 5.0,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                clipBehavior: Clip.antiAlias,
                child: CardImageButton(
                  coverImageUrl: coverImageUrl,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ComicPage(snapshot.data),
                    ));
                  },
                ),
              ),
            ),
            SizedBox(height: 5.0),
            Text(
              data['name'] ?? snapshot.data.id,
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

class CardImageButton extends StatelessWidget {
  final String coverImageUrl;
  final Function() onTap;

  const CardImageButton({Key key, this.coverImageUrl, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (coverImageUrl?.isEmpty ?? true) {
      return InkWell(
        onTap: onTap,
        child: Icon(Icons.error, color: Colors.red),
      );
    } else {
      return OptimizedCacheImage(
        imageUrl: coverImageUrl,
        imageBuilder: (context, imageProvider) {
          return Ink.image(
            image: imageProvider,
            fit: BoxFit.cover,
            child: InkWell(
              onTap: onTap,
            ),
          );
        },
        placeholder: (context, url) {
          return Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              // Draw a solid element to fade out to image
              Container(
                color: Colors.white,
              ),
              LinearProgressIndicator(),
            ],
          );
        },
        errorWidget: (context, url, error) => Icon(Icons.error),
        fadeInDuration: Duration(seconds: 2),
      );
    }
  }
}
