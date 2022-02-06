import 'package:comicwrap_f/utils/download.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardImageButton extends ConsumerWidget {
  final String? coverImageUrl;
  final Function()? onTap;

  const CardImageButton({Key? key, this.coverImageUrl, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final url = coverImageUrl;
    if (url == null) {
      return _getEmptyImageButton();
    } else {
      final progress = watch(downloadImageFamily(url));
      return progress.when(
        data: (data) {
          if (data is ImageResponse) {
            // Image downloaded, display image
            return Ink.image(
              image: data.image,
              fit: BoxFit.cover,
              child: InkWell(
                onTap: onTap,
              ),
            );
          } else if (data is DownloadProgress) {
            // Image is still downloading, display progress
            return Stack(
              alignment: AlignmentDirectional.bottomCenter,
              children: [
                LinearProgressIndicator(
                  value: data.progress,
                  minHeight: 8.0,
                ),
              ],
            );
          } else {
            return ErrorWidget('FileResponse is not of known type.');
          }
        },
        loading: () => _getEmptyImageButton(),
        error: (error, stack) => ErrorWidget(error),
      );
    }
  }

  Widget _getEmptyImageButton() {
    return InkWell(
      onTap: onTap,
    );
  }
}
