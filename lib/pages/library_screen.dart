import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:comicwrap_f/environment.dart';
import 'package:comicwrap_f/models/collection_models.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class LibraryScreen extends StatefulWidget {
  final Client client;

  const LibraryScreen({Key? key, required this.client}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Database _database;
  late Future<Response<dynamic>> _listComics;
  late Functions _functions;

  @override
  void initState() {
    _database = Database(widget.client);
    _listComics = _database.listDocuments(collectionId: appwriteColComics);

    _functions = Functions(widget.client);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Rebuild UI
          setState(() {
            _listComics =
                _database.listDocuments(collectionId: appwriteColComics);
          });

          // Display refresh indicator until finished
          await _listComics;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120.0,
              flexibleSpace: const FlexibleSpaceBar(
                title: Text('Library'),
              ),
              actions: [
                IconButton(
                    icon: Icon(
                      Icons.library_add,
                      color: Theme.of(context).primaryIconTheme.color,
                    ),
                    onPressed: () => _onAddPressed(context)),
              ],
              leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).primaryIconTheme.color,
                  ),
                  onPressed: () {}),
            ),
            FutureBuilder<Response<dynamic>>(
              future: _listComics,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Text('Error getting comics :('),
                    );
                  } else {
                    return SliverToBoxAdapter(
                      child: Text('Getting comics...'),
                    );
                  }
                }

                if (snapshot.data == null) {
                  return SliverToBoxAdapter(
                    child: Text('Snapshot data is null!'),
                  );
                }

                final data = snapshot.data!.data;
                final comics = DocumentsListModel.fromJson(data);

                if (comics.sum == 0) {
                  return SliverToBoxAdapter(
                    child: Text('User has no library!'),
                  );
                }

                return SliverPadding(
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150.0,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.54,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final comic = ComicDocumentModel.fromJson(
                            comics.documents[index]);

                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          columnCount: 3,
                          duration: Duration(milliseconds: 200),
                          delay: Duration(milliseconds: 50),
                          child: ScaleAnimation(
                            scale: 0.85,
                            child: FadeInAnimation(
                              child: ComicInfoCard(comic),
                            ),
                          ),
                        );
                      },
                      childCount: comics.documents.length,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _onAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddComicDialog(functions: _functions);
      },
    );
  }
}

class AddComicDialog extends StatefulWidget {
  final Functions functions;

  AddComicDialog({Key? key, required this.functions}) : super(key: key);

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

    try {
      // Start function execution
      final startedResponse = await widget.functions.createExecution(
          functionId: appwriteFuncUseAddComic, data: _url.text);

      // Poll for execution state
      while ((await widget.functions.getExecution(
                  functionId: appwriteFuncUseAddComic,
                  executionId: startedResponse.data['\$id']))
              .data['status'] ==
          'waiting') {
        // Wait a bit between polls
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Function completed! Display result... TODO: handle success
      final completeResponse = await widget.functions.getExecution(
          functionId: appwriteFuncUseAddComic,
          executionId: startedResponse.data['\$id']);
      setState(() {
        _urlErrorText = completeResponse.data['stdout'];
        _preventPop = false;
      });

      return;
    } on AppwriteException catch (e) {
      setState(() {
        _urlErrorText = 'Error ${e.code}: ${e.message}';
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
