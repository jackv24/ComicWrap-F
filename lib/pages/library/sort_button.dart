import 'package:comicwrap_f/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum SortChangeOption {
  lastRead,
  lastUpdated,
  title,
  reverse,
}

class SortButton extends StatelessWidget {
  final SortOption sortOption;
  final bool reverse;
  final void Function(SortChangeOption) onSortChange;

  const SortButton(
      {Key? key,
      required this.onSortChange,
      required this.sortOption,
      required this.reverse})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final String text;
    switch (sortOption) {
      case SortOption.lastRead:
        text = loc.sortLastRead;
        break;
      case SortOption.lastUpdated:
        text = loc.sortLastUpdated;
        break;
      case SortOption.title:
        text = loc.sortTitle;
        break;
    }

    final theme = Theme.of(context);

    return TextButton(
      onPressed: () => _showSortMenu(context),
      style: TextButton.styleFrom(
        primary: theme.colorScheme.onBackground,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(text),
          ),
          Transform.scale(
            scaleY: reverse ? -1.0 : 1.0,
            child: const Icon(Icons.sort),
          ),
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final offset = Offset(0.0, button.size.height);
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final loc = AppLocalizations.of(context);

    final result = await showMenu<SortChangeOption>(
      context: context,
      position: position,
      items: [
        CheckedPopupMenuItem(
          value: SortChangeOption.lastRead,
          checked: sortOption == SortOption.lastRead,
          child: Text(loc.sortLastRead),
        ),
        CheckedPopupMenuItem(
          value: SortChangeOption.lastUpdated,
          checked: sortOption == SortOption.lastUpdated,
          child: Text(loc.sortLastUpdated),
        ),
        CheckedPopupMenuItem(
          value: SortChangeOption.title,
          checked: sortOption == SortOption.title,
          child: Text(loc.sortTitle),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: SortChangeOption.reverse,
          checked: reverse,
          child: Text(loc.sortReverse),
        ),
      ],
    );

    if (result != null) {
      onSortChange(result);
    }
  }
}
