import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/system/database.dart';
import 'package:comicwrap_f/widgets/comic_info_card.dart';
import 'package:comicwrap_f/widgets/scaffold_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class LibraryScreen extends StatelessWidget implements ScaffoldScreen {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error reading user stream');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading user data...");
        }

        var data = snapshot.data.data();
        List<dynamic> comicPaths = data['library'];

        if (comicPaths == null) return Text('User has no library!');

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 0.57,
          ),
          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          itemCount: comicPaths.length,
          itemBuilder: (context, index) {
            final comic = comicPaths[index];
            Widget comicWidget;
            try {
              comicWidget =
                  ComicInfoCard((comic as DocumentReference).snapshots());
            } catch (e) {
              comicWidget = Text('ERROR: ${e.toString()}');
            }
            return AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: 3,
              duration: Duration(milliseconds: 200),
              delay: Duration(milliseconds: 100),
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
    );
  }

  void _onAddPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddComicDialog(() async {
          // TODO
          // No errors! :D
          return null;
        });
      },
    );
  }

  @override
  String get title => 'Library';

  @override
  List<Widget> getActions(BuildContext context) {
    return [
      IconButton(
          icon: Icon(
            Icons.library_add,
            color: Theme.of(context).primaryIconTheme.color,
          ),
          onPressed: () => _onAddPressed(context)),
    ];
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

    // TODO: Implement
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _preventPop = false;
    });

    // TODO: Display any error

    // Close dialog if there were no errors
    Navigator.of(context).pop();
  }
}
