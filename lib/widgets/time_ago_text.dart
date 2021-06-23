import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class TimeAgoText extends StatefulWidget {
  final DateTime? time;
  final Widget Function(String) builder;

  const TimeAgoText({Key? key, this.time, required this.builder})
      : super(key: key);

  @override
  _TimeAgoTextState createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  Timer? _timer;
  late String _text;

  @override
  void initState() {
    if (widget.time == null) {
      // No need to update periodically if it'll never change
      _text = 'never';
    } else {
      _text = timeago.format(widget.time!);

      // Update time display periodically
      _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _text = timeago.format(widget.time!);
        });
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_text);
  }
}
