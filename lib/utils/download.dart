import 'package:comicwrap_f/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

final imageCacheManagerProvider = Provider<ImageCacheManager>((ref) {
  return DefaultCacheManager();
});

final downloadImageFamily =
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
  final ImageProvider image;

  const ImageResponse(this.image, String originalUrl) : super(originalUrl);
}

final downloadCoverImagePaletteFamily = StreamProvider.autoDispose
    .family<PaletteGenerator?, String>((ref, comicId) {
  final cacheManager = ref.watch(imageCacheManagerProvider);
  final sharedComic = ref.watch(sharedComicFamily(comicId));

  return sharedComic.when(
    loading: () => const Stream.empty(),
    error: (error, stack) => Stream.error(error, stack),
    data: (comic) {
      if (comic == null) return Stream.value(null);

      final coverUrl =
          getValidCoverImageUrl(comic.coverImageUrl, comic.scrapeUrl);
      if (coverUrl == null) return Stream.value(null);

      return cacheManager
          .getImageFile(coverUrl, withProgress: true)
          .asyncMap((event) async {
        if (event is FileInfo) {
          return PaletteGenerator.fromImageProvider(FileImage(event.file));
        }
        return null;
      });
    },
  );
});

String? getValidCoverImageUrl(String? coverImageUrl, String scrapeUrl) {
  // If cover url is relative, make it absolute
  if (coverImageUrl != null && !coverImageUrl.startsWith('http')) {
    if (scrapeUrl.isNotEmpty) {
      coverImageUrl = scrapeUrl + coverImageUrl;
    }
  }

  return coverImageUrl;
}
