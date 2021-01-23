import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComicPage extends StatelessWidget {
  final DocumentSnapshot doc;

  const ComicPage(this.doc, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final collectionRef =
        doc.reference.collection('pages').orderBy('index', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name'] ?? doc.id),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: collectionRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading...");
          }

          final docs = snapshot.data.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return ListTile(
                title: Text(data['text'] ?? '!!Page $index!!'),
              );
            },
          );
        },
      ),
    );
  }
}
