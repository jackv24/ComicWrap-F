import 'package:comicwrap_f/models/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class UserModel with _$UserModel {
  factory UserModel({
    required bool dummyData,
  }) = _UserModel;

  factory UserModel.fromJson(Json json) => _$UserModelFromJson(json);
}
