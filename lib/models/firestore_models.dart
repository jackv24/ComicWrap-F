import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'firestore_models.g.dart';

class _SharedComicModelDocumentReferenceConverter
    implements
        JsonConverter<DocumentReference<SharedComicModel>,
            DocumentReference<Map<String, dynamic>>> {
  const _SharedComicModelDocumentReferenceConverter();

  @override
  DocumentReference<SharedComicModel> fromJson(
          DocumentReference<Map<String, dynamic>> json) =>
      json.withConverter(
        fromFirestore: (snapshot, _) =>
            SharedComicModel.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson(),
      );

  @override
  DocumentReference<Map<String, dynamic>> toJson(
          DocumentReference<SharedComicModel> data) =>
      FirebaseFirestore.instance.doc(data.path);
}

@JsonSerializable()
@_SharedComicModelDocumentReferenceConverter()
class UserComicModel {
  final DocumentReference<SharedComicModel> sharedDoc;

  // Type not supported by code generator
  @JsonKey(ignore: true)
  late Timestamp? lastReadTime;

  UserComicModel({required this.sharedDoc, this.lastReadTime});

  factory UserComicModel.fromJson(Map<String, dynamic> json) =>
      _$UserComicModelFromJson(json)..lastReadTime = json['lastReadTime'];

  Map<String, dynamic> toJson() =>
      _$UserComicModelToJson(this)..['lastReadTime'] = lastReadTime;
}

@JsonSerializable()
class SharedComicModel {
  final String? name;
  final String? coverImageUrl;
  final String scrapeUrl;

  SharedComicModel({this.name, this.coverImageUrl, required this.scrapeUrl});

  factory SharedComicModel.fromJson(Map<String, dynamic> json) =>
      _$SharedComicModelFromJson(json);

  Map<String, dynamic> toJson() => _$SharedComicModelToJson(this);
}

@JsonSerializable()
class SharedComicPageModel {
  final String text;

  // Type not supported by code generator
  @JsonKey(ignore: true)
  late Timestamp? scrapeTime;

  SharedComicPageModel({required this.text});

  factory SharedComicPageModel.fromJson(Map<String, dynamic> json) =>
      _$SharedComicPageModelFromJson(json)..scrapeTime = json['scrapeTime'];

  Map<String, dynamic> toJson() =>
      _$SharedComicPageModelToJson(this)..['scrapeTime'] = scrapeTime;
}
