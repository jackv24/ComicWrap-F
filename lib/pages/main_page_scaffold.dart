import 'package:flutter/material.dart';

class MainPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> bodySlivers;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  const MainPageScaffold(
      {Key? key,
      required this.title,
      required this.bodySlivers,
      this.appBarActions,
      this.floatingActionButton})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: TextStyle(color: colorScheme.onBackground),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: appBarActions,
            backgroundColor: colorScheme.background,
            foregroundColor: colorScheme.onBackground,
          ),
          ...bodySlivers
        ],
      ),
    );
  }
}
