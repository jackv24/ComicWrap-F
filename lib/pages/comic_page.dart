import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComicPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const ComicPage(this.doc, {Key key}) : super(key: key);

  @override
  _ComicPageState createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  List<DocumentSnapshot> pages = [];
  bool isLoading = false;
  bool hasMore = true;
  int documentLimit = 15;
  DocumentSnapshot lastDocument;
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();

    // Scrollview won't build if we don't have any pages
    _getPages();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final data = doc.data();

    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;

      // Fetch more documents if user scrolls 20% of device height
      double delta = MediaQuery.of(context).size.height * 0.2;
      if (maxScroll - currentScroll <= delta) {
        _getPages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name'] ?? doc.id),
      ),
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          pages.length == 0
              ? Center(child: Text('No pages...'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final data = pages[index].data();
                    return ListTile(
                      title: Text(data['text'] ?? '!!Page $index!!'),
                    );
                  },
                ),
          isLoading
              ? Container(
                  padding: EdgeInsets.all(12),
                  alignment: AlignmentDirectional.bottomCenter,
                  child: CircularProgressIndicator(),
                )
              : Container(),
        ],
      ),
    );
  }

  void _getPages() async {
    if (!hasMore) {
      return;
    }

    if (isLoading) {
      return;
    }

    print('Loading more pages');

    setState(() {
      isLoading = true;
    });

    final query = widget.doc.reference
        .collection('pages')
        .orderBy('index', descending: true);

    QuerySnapshot querySnapshot;
    if (lastDocument == null) {
      querySnapshot = await query.limit(documentLimit).get();
    } else {
      querySnapshot = await query
          .startAfterDocument(lastDocument)
          .limit(documentLimit)
          .get();
    }

    if (querySnapshot.docs.length < documentLimit) {
      hasMore = false;
    }

    final docs = querySnapshot.docs;
    lastDocument = docs.last;
    pages.addAll(docs);

    setState(() {
      isLoading = false;
    });
  }
}
