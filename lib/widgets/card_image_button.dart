import 'package:comicwrap_f/utils/download.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardImageButton extends ConsumerWidget {
  final String? coverImageUrl;
  final Function()? onTap;
  final Function(Offset?)? onLongPressed;

  Offset? _lastTapPosition;

  CardImageButton({
    Key? key,
    this.coverImageUrl,
    this.onTap,
    this.onLongPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final url = coverImageUrl;
    if (url == null) {
      return _getInkWell();
    } else {
      final progress = watch(downloadImageFamily(url));
      return progress.when(
        data: (data) {
          if (data is ImageResponse) {
            // Image downloaded, display image
            return Ink.image(
              image: data.image,
              fit: BoxFit.cover,
              child: _getInkWell(),
            );
          } else if (data is DownloadProgress) {
            // Image is still downloading, display progress
            return _getInkWell(
                child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(),
                LinearProgressIndicator(
                  value: data.progress,
                  minHeight: 8.0,
                ),
              ],
            ));
          } else {
            return ErrorWidget('FileResponse is not of known type.');
          }
        },
        loading: () => _getInkWell(),
        error: (error, stack) => ErrorWidget(error),
      );
    }
  }

  Widget _getInkWell({Widget? child}) {
    // Only set long press handlers if required
    final void Function(TapDownDetails)? onTapDown;
    final void Function()? onLongPress;
    if (onLongPressed != null) {
      onTapDown = (details) => _lastTapPosition = details.globalPosition;
      onLongPress = () => onLongPressed!(_lastTapPosition);
    } else {
      onTapDown = null;
      onLongPress = null;
    }

    return InkWell(
      onTap: onTap,
      onTapDown: onTapDown,
      onLongPress: onLongPress,
      child: child,
    );
  }
}
