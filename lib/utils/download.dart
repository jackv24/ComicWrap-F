import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageCacheManagerProvider = Provider<ImageCacheManager>((ref) {
  return DefaultCacheManager();
});

final downloadImageProvider =
    StreamProvider.autoDispose.family<FileResponse, String>((ref, url) {
  final cacheManager = ref.watch(imageCacheManagerProvider);
  return cacheManager.getImageFile(url, withProgress: true).map((event) {
    if (event is FileInfo) {
      return ImageResponse(FileImage(event.file), event.originalUrl);
    }
    return event;
  });
});

class ImageResponse extends FileResponse {
  const ImageResponse(this.image, String originalUrl) : super(originalUrl);

  final ImageProvider image;
}
