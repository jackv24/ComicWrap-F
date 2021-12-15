import 'dart:async';

import 'package:flutter/material.dart';

class MoreActionButton extends StatelessWidget {
  final List<FunctionListItem> actions;

  const MoreActionButton({Key? key, required this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.more_horiz),
      ),
      itemBuilder: (context) {
        return List.generate(actions.length, (index) {
          return PopupMenuItem(
            value: index,
            child: actions[index].child,
          );
        });
      },
      onSelected: (int index) => actions[index].onSelected(context),
    );
  }
}

class FunctionListItem {
  final Widget child;
  final Future Function(BuildContext) onSelected;

  const FunctionListItem({required this.child, required this.onSelected});
}
