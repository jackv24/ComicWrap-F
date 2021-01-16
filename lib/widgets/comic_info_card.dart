import 'package:flutter/material.dart';

class ComicInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 8.5 / 11.0,
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(height: 5.0),
        Text(
          'Comic Name Here',
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
  }
}
