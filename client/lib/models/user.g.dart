// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      theme: json['theme'] as String,
      dynamicBg: json['dynamic_bg'] as bool,
      musicVolume: json['music_volume'] as int,
      moodSensitivity: (json['mood_sensitivity'] as num).toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'full_name': instance.fullName,
      'theme': instance.theme,
      'dynamic_bg': instance.dynamicBg,
      'music_volume': instance.musicVolume,
      'mood_sensitivity': instance.moodSensitivity,
      'created_at': instance.createdAt?.toIso8601String(),
    };