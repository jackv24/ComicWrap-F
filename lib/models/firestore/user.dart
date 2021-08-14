import 'package:comicwrap_f/models/common.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class UserModel {
  // Empty for now - just for type safety
  UserModel();

  factory UserModel.fromJson(Json json) => _$UserModelFromJson(json);

  Json toJson() => _$UserModelToJson(this);
}
