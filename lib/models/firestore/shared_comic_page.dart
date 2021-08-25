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

  SharedComicPageModel({required this.text});

  factory SharedComicPageModel.fromJson(Json json) =>
      _$SharedComicPageModelFromJson(json)..scrapeTime = json['scrapeTime'];

  Json toJson() =>
      _$SharedComicPageModelToJson(this)..['scrapeTime'] = scrapeTime;
}

DocumentReference<SharedComicPageModel>? sharedComicPageFromJson(
        DocumentReference<Json>? json) =>
    json?.withConverter(
      fromFirestore: (snapshot, _) =>
          SharedComicPageModel.fromJson(snapshot.data()!),
      toFirestore: (data, _) => data.toJson(),
    );

// TODO: Use Riverpod, replace references with ID and get ref manually
DocumentReference<Json>? sharedComicPageToJson(
        DocumentReference<SharedComicPageModel>? data) =>
    data != null ? FirebaseFirestore.instance.doc(data.path) : null;
