import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/common.dart';
import 'package:comicwrap_f/models/firestore/shared_comic_page.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_comic.g.dart';

@JsonSerializable()
class UserComicModel {
  // Type not supported by code generator
  @JsonKey(ignore: true)
  late Timestamp? lastReadTime;

  @JsonKey(fromJson: sharedComicPageFromJson, toJson: sharedComicPageToJson)
  final DocumentReference<SharedComicPageModel>? currentPage;

  UserComicModel({this.lastReadTime, this.currentPage});

  factory UserComicModel.fromJson(Json json) =>
      _$UserComicModelFromJson(json)..lastReadTime = json['lastReadTime'];

  Json toJson() =>
      _$UserComicModelToJson(this)..['lastReadTime'] = lastReadTime;
}
