import 'package:flutter/material.dart';

class HomePageScreen extends StatelessWidget {
  final Widget title;
  final Widget bodySliver;
  final List<Widget>? appBarActions;

  const HomePageScreen(
      {Key? key,
      required this.title,
      required this.bodySliver,
      this.appBarActions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: title,
            ),
            actions: appBarActions,
          ),
          bodySliver
        ],
      ),
    );
  }
}
