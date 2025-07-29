// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoodReference _$MoodReferenceFromJson(Map<String, dynamic> json) =>
    MoodReference(
      id: json['id'] as int,
      moodName: json['mood_name'] as String,
      tempoElectronic: json['tempo_electronic'] as int,
      tempoClassic: json['tempo_classic'] as int,
      tempoLofi: json['tempo_lofi'] as int,
      tempoCustom: json['tempo_custom'] as int,
    );

Map<String, dynamic> _$MoodReferenceToJson(MoodReference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mood_name': instance.moodName,
      'tempo_electronic': instance.tempoElectronic,
      'tempo_classic': instance.tempoClassic,
      'tempo_lofi': instance.tempoLofi,
      'tempo_custom': instance.tempoCustom,
    };

MoodTrigger _$MoodTriggerFromJson(Map<String, dynamic> json) => MoodTrigger(
      moodName: json['mood_name'] as String,
      tempo: json['tempo'] as int,
      backgroundImageUrl: json['background_image_url'] as String?,
      transitionType: json['transition_type'] as String,
      timestamp: json['timestamp'] as int,
    );

Map<String, dynamic> _$MoodTriggerToJson(MoodTrigger instance) =>
    <String, dynamic>{
      'mood_name': instance.moodName,
      'tempo': instance.tempo,
      'background_image_url': instance.backgroundImageUrl,
      'transition_type': instance.transitionType,
      'timestamp': instance.timestamp,
    };

// MoodBackground class
class MoodBackground {
  final int id;
  final int moodId;
  final String backgroundPath;

  MoodBackground({
    required this.id,
    required this.moodId,
    required this.backgroundPath,
  });

  factory MoodBackground.fromJson(Map<String, dynamic> json) {
    return MoodBackground(
      id: json['id'] as int,
      moodId: json['mood_id'] as int,
      backgroundPath: json['background_path'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood_id': moodId,
      'background_path': backgroundPath,
    };
  }
}