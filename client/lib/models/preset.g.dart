// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Preset _$PresetFromJson(Map<String, dynamic> json) => Preset(
      id: json['id'] as int,
      creatorId: json['creator_id'] as int,
      presetName: json['preset_name'] as String,
      bookId: json['book_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      moodMaps: (json['mood_maps'] as List<dynamic>?)
          ?.map((e) => MoodMap.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PresetToJson(Preset instance) => <String, dynamic>{
      'id': instance.id,
      'creator_id': instance.creatorId,
      'preset_name': instance.presetName,
      'book_id': instance.bookId,
      'created_at': instance.createdAt.toIso8601String(),
      'mood_maps': instance.moodMaps?.map((e) => e.toJson()).toList(),
    };

MoodMap _$MoodMapFromJson(Map<String, dynamic> json) => MoodMap(
      id: json['id'] as int,
      presetId: json['preset_id'] as int,
      chapter: json['chapter'] as int,
      pageFraction: (json['page_fraction'] as num).toDouble(),
      moodId: json['mood_id'] as int?,
      backgroundId: json['background_id'] as int?,
      transitionType: json['transition_type'] as String,
    );

Map<String, dynamic> _$MoodMapToJson(MoodMap instance) => <String, dynamic>{
      'id': instance.id,
      'preset_id': instance.presetId,
      'chapter': instance.chapter,
      'page_fraction': instance.pageFraction,
      'mood_id': instance.moodId,
      'background_id': instance.backgroundId,
      'transition_type': instance.transitionType,
    };