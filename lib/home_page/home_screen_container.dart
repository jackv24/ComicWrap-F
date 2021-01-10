import 'package:flutter/material.dart';

class HomeScreenContainer extends StatelessWidget {
  final Widget child;

  HomeScreenContainer(this.child, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: child,
      onRefresh: _onRefresh,
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(Duration(seconds: 2));
  }
}
