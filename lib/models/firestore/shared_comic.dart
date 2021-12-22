import 'package:comicwrap_f/models/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_comic.freezed.dart';
part 'shared_comic.g.dart';

@freezed
class SharedComicModel with _$SharedComicModel {
  factory SharedComicModel({
    String? name,
    String? coverImageUrl,
    required String scrapeUrl,
    @Default(false) bool isImporting,
  }) = _SharedComicModel;

  factory SharedComicModel.fromJson(Json json) =>
      _$SharedComicModelFromJson(json);
}
