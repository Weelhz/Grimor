import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String? fullName;
  final String theme;
  final bool dynamicBg;
  final int musicVolume;
  final double moodSensitivity;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.fullName,
    required this.theme,
    required this.dynamicBg,
    required this.musicVolume,
    required this.moodSensitivity,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? theme,
    bool? dynamicBg,
    int? musicVolume,
    double? moodSensitivity,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      theme: theme ?? this.theme,
      dynamicBg: dynamicBg ?? this.dynamicBg,
      musicVolume: musicVolume ?? this.musicVolume,
      moodSensitivity: moodSensitivity ?? this.moodSensitivity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}