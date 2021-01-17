import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComicPage extends StatelessWidget {
  final DocumentSnapshot doc;

  const ComicPage(this.doc, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = doc.data();

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name'] ?? '!!!null name!!!'),
      ),
    );
  }
}
