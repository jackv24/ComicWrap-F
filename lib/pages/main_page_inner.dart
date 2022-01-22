import 'package:comicwrap_f/constants.dart';
import 'package:flutter/material.dart';

class MainPageInner extends StatelessWidget {
  final Widget sliver;

  const MainPageInner({Key? key, required this.sliver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      if (width > wideScreenThreshold) {
        final totalPadding = width - wideScreenThreshold;
        return SliverPadding(
          padding: EdgeInsets.symmetric(
              horizontal: (totalPadding / 2) + wideScreenExtraPadding),
          sliver: sliver,
        );
      } else {
        return sliver;
      }
    });
  }
}
