import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:comicwrap_f/system/database.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rxdart/rxdart.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  BehaviorSubject<QuerySnapshot> _userComicsSubject;
  StreamSubscription _userDocComicsSub;

  @override
  void initState() {
    // Keep latest event for build
    _userComicsSubject = BehaviorSubject<QuerySnapshot>();

    // User can change through authentication
    getUserStream().listen((userDocSnapshot) async {
      // Cancel previous stream sub before subbing to new one
      if (_userDocComicsSub != null) {
        await _userDocComicsSub.cancel();
      }

      // If user changes sub to new user comics collection
      _userDocComicsSub = userDocSnapshot.reference
          .collection('comics')
          .orderBy('lastReadTime', descending: true)
          .snapshots()
          .listen((comicsCollectionSnap) {
        _userComicsSubject.add(comicsCollectionSnap);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
        actions: [
          IconButton(
              icon: Icon(
                Icons.library_add,
                color: Theme.of(context).primaryIconTheme.color,
              ),
              onPressed: () => _onAddPressed(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userComicsSubject.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error reading user comics stream');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading user comics stream...");
          }

          final userComicDocs = snapshot.data.docs;
          if (userComicDocs.length == 0) return Text('User has no library!');

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 0.54,
            ),
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            itemCount: userComicDocs.length,
            itemBuilder: (context, index) {
              final userComic = userComicDocs[index];
              final userComicData = userComic.data();
              final DocumentReference sharedComic = userComicData['sharedDoc'];

              Widget comicWidget;
              try {
                comicWidget = ComicInfoCard(sharedComic);
              } catch (e) {
                comicWidget = Text('ERROR: ${e.toString()}');
              }
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 3,
                duration: Duration(milliseconds: 200),
                delay: Duration(milliseconds: 50),
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

  void _onAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddComicDialog(() async {
          HttpsCallable callable =
              FirebaseFunctions.instance.httpsCallable('startComicScrape');
          final result = await callable('https://www.goodbyetohalos.com/');
          print(result.data);

          // No errors! :D
          return null;
        });
      },
    );
  }
}

class AddComicDialog extends StatefulWidget {
  final Future<String> Function() onAdded;

  AddComicDialog(this.onAdded, {Key key}) : super(key: key);

  @override
  _AddComicDialogState createState() => _AddComicDialogState();
}

class _AddComicDialogState extends State<AddComicDialog> {
  String _urlErrorText;
  final _url = TextEditingController();

  bool _preventPop = false;

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);

    return WillPopScope(
      onWillPop: () async => !_preventPop,
      child: AlertDialog(
        title: Text('Add Comic'),
        content: SingleChildScrollView(
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.web),
              labelText: 'URL',
              hintText: 'http://www.example.com/',
              errorText: _urlErrorText,
            ),
            keyboardType: TextInputType.url,
            onEditingComplete: () => node.nextFocus(),
            controller: _url,
            enabled: !_preventPop,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Add'),
            onPressed: _preventPop ? null : () => _submit(),
          ),
          FlatButton(
            child: Text('Cancel'),
            onPressed:
                _preventPop ? null : () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Clear previous error while waiting
    setState(() {
      _urlErrorText = null;
      _preventPop = true;
    });

    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('startComicScrape');

    try {
      final result = await callable(_url.text);
      print('Returned result: ' + result.data);
    } on FirebaseFunctionsException catch (e) {
      print('Caught error: ' + e.code);
      setState(() {
        _urlErrorText = e.message;
        _preventPop = false;
      });

      return;
    }

    setState(() {
      _preventPop = false;
    });

    // Close dialog if there were no errors
    Navigator.of(context).pop();
  }
}
