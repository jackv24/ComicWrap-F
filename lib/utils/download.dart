import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadImageProvider =
    StreamProvider.autoDispose.family<FileResponse, String>((ref, url) {
  return DefaultCacheManager().getImageFile(url, withProgress: true);
});
