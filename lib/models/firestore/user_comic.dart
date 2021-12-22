import 'package:comicwrap_f/models/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_comic.freezed.dart';
part 'user_comic.g.dart';

@freezed
class UserComicModel with _$UserComicModel {
  factory UserComicModel({
    String? currentPageId,
    String? newFromPageId,
    @TimestampNullConverter() DateTime? lastReadTime,
  }) = _UserComicModel;

  factory UserComicModel.fromJson(Json json) => _$UserComicModelFromJson(json);
}
