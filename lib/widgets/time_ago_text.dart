import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class TimeAgoText extends StatefulWidget {
  final DateTime? time;
  final Widget Function(String) builder;

  const TimeAgoText({Key? key, this.time, required this.builder})
      : super(key: key);

  @override
  State<TimeAgoText> createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  Timer? _timer;
  late String? _text;

  @override
  void initState() {
    _createTimeUpdateTimer();

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  void didUpdateWidget(TimeAgoText oldWidget) {
    if (oldWidget.time != widget.time) {
      _timer?.cancel();
      _timer = null;
      _createTimeUpdateTimer();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final text = _text ?? AppLocalizations.of(context).timeAgoNever;
    return widget.builder(text);
  }

  void _createTimeUpdateTimer() {
    if (widget.time == null) {
      // No need to update periodically if it'll never change
      _text = null;
    } else {
      _text = timeago.format(widget.time!);

      // Update time display periodically
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _text = timeago.format(widget.time!);
        });
      });
    }
  }
}
