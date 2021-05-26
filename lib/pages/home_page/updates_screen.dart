import 'package:comicwrap_f/pages/home_page/home_page_screen.dart';
import 'package:flutter/material.dart';

class UpdatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomePageScreen(
      title: Text('Updates'),
      bodySliver: SliverToBoxAdapter(
        child: Text("TODO"),
      ),
    );
  }
}
