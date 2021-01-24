import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComicWebPage extends StatelessWidget {
  final DocumentSnapshot page;

  const ComicWebPage(this.page, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = page.data();

    return Scaffold(
      appBar: AppBar(
        title: Text(data['text'] ?? 'NULL'),
      ),
      body: Text('TODO'),
    );
  }
}
