import 'package:comicwrap_f/models/common.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shared_comic.g.dart';

@JsonSerializable()
class SharedComicModel {
  final String? name;
  final String? coverImageUrl;
  final String scrapeUrl;

  SharedComicModel({this.name, this.coverImageUrl, required this.scrapeUrl});

  factory SharedComicModel.fromJson(Json json) =>
      _$SharedComicModelFromJson(json);

  Json toJson() => _$SharedComicModelToJson(this);
}
