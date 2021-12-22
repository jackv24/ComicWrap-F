import 'package:comicwrap_f/models/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_comic_page.freezed.dart';
part 'shared_comic_page.g.dart';

@freezed
class SharedComicPageModel with _$SharedComicPageModel {
  factory SharedComicPageModel({
    required String text,
    @TimestampNullConverter() DateTime? scrapeTime,
  }) = _SharedComicPageModel;

  factory SharedComicPageModel.fromJson(Json json) =>
      _$SharedComicPageModelFromJson(json);
}
