import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comicwrap_f/models/common.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shared_comic_page.g.dart';

@JsonSerializable()
class SharedComicPageModel {
  final String text;

  // Type not supported by code generator
  @JsonKey(ignore: true)
  late Timestamp? scrapeTime;

  SharedComicPageModel({required this.text, this.scrapeTime});

  factory SharedComicPageModel.fromJson(Json json) =>
      _$SharedComicPageModelFromJson(json)..scrapeTime = json['scrapeTime'];

  Json toJson() =>
      _$SharedComicPageModelToJson(this)..['scrapeTime'] = scrapeTime;
}
