import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'firestore_models.g.dart';

typedef Json = Map<String, dynamic>;

class _SharedComicModelDocumentReferenceConverter
    implements
        JsonConverter<DocumentReference<SharedComicModel>,
            DocumentReference<Json>> {
  const _SharedComicModelDocumentReferenceConverter();

  @override
  DocumentReference<SharedComicModel> fromJson(DocumentReference<Json> json) =>
      json.withConverter(
        fromFirestore: (snapshot, _) =>
            SharedComicModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      );

  @override
  DocumentReference<Json> toJson(DocumentReference<SharedComicModel> data) =>
      FirebaseFirestore.instance.doc(data.path);
}

DocumentReference<SharedComicPageModel>? sharedComicPageFromJson(
        DocumentReference<Json>? json) =>
    json?.withConverter(
      fromFirestore: (snapshot, _) =>
          SharedComicPageModel.fromJson(snapshot.data()!),
      toFirestore: (data, _) => data.toJson(),
    );

DocumentReference<Json>? sharedComicPageToJson(
        DocumentReference<SharedComicPageModel>? data) =>
    data != null ? FirebaseFirestore.instance.doc(data.path) : null;

@JsonSerializable()
@_SharedComicModelDocumentReferenceConverter()
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
