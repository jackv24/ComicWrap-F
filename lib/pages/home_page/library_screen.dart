import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:comicwrap_f/models/firestore_models.dart';
import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:comicwrap_f/pages/home_page/settings_screen.dart';
import 'package:comicwrap_f/system/database.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rxdart/rxdart.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late BehaviorSubject<QuerySnapshot<UserComicModel>> _userComicsSubject;
  StreamSubscription? _userDocComicsSub;

  @override
  void initState() {
    // Keep latest event for build
    _userComicsSubject = BehaviorSubject<QuerySnapshot<UserComicModel>>();

    // User can change through authentication
    getUserStream().listen((userDocSnapshot) async {
      // Cancel previous stream sub before subbing to new one
      _userDocComicsSub?.cancel();

      // If user changes sub to new user comics collection
      _userDocComicsSub = userDocSnapshot.reference
          .collection('comics')
          .withConverter<UserComicModel>(
            fromFirestore: (snapshot, _) =>
                UserComicModel.fromJson(snapshot.data()!),
            toFirestore: (comic, _) => comic.toJson(),
          )
          .orderBy('lastReadTime', descending: true)
          .snapshots()
          .listen((comicsCollectionSnap) {
        _userComicsSubject.add(comicsCollectionSnap);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _userDocComicsSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePageScreen(
      title: Text('Library'),
      appBarActions: [
        IconButton(
            icon: Icon(
              Icons.library_add,
            ),
            onPressed: () => _onAddPressed(context)),
        IconButton(
            icon: Icon(
              Icons.settings_rounded,
            ),
            onPressed: () => _onSettingsPressed(context)),
      ],
      bodySliver: StreamBuilder<QuerySnapshot<UserComicModel>>(
        stream: _userComicsSubject.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Text('Error reading user comics stream'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverToBoxAdapter(
              child: Text("Loading user comics stream..."),
            );
          }

          final userComicDocs = snapshot.data!.docs;
          if (userComicDocs.length == 0) {
            return SliverToBoxAdapter(
              child: Text('User has no library!'),
            );
          }

          return SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150.0,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 0.54,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  Widget comicWidget;
                  try {
                    comicWidget = ComicInfoCard(
                      userComicSnapshot: userComicDocs[index],
                    );
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
                childCount: userComicDocs.length,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddComicDialog();
      },
    );
  }

  void _onSettingsPressed(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) {
        return SettingsScreen();
      },
    ));
  }
}

class AddComicDialog extends StatefulWidget {
  AddComicDialog({Key? key}) : super(key: key);

  @override
  _AddComicDialogState createState() => _AddComicDialogState();
}

class _AddComicDialogState extends State<AddComicDialog> {
  String? _urlErrorText;
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
          TextButton(
            child: Text('Add'),
            onPressed: _preventPop ? null : () => _submit(),
          ),
          TextButton(
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
        FirebaseFunctions.instance.httpsCallable('addUserComic');

    try {
      final HttpsCallableResult<dynamic> result = await callable(_url.text);
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
