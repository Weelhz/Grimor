import 'package:json_annotation/json_annotation.dart';

part 'mood.g.dart';

@JsonSerializable()
class MoodReference {
  final int id;
  final String moodName;
  final int tempoElectronic;
  final int tempoClassic;
  final int tempoLofi;
  final int tempoCustom;

  MoodReference({
    required this.id,
    required this.moodName,
    required this.tempoElectronic,
    required this.tempoClassic,
    required this.tempoLofi,
    required this.tempoCustom,
  });

  factory MoodReference.fromJson(Map<String, dynamic> json) => _$MoodReferenceFromJson(json);
  Map<String, dynamic> toJson() => _$MoodReferenceToJson(this);
}

@JsonSerializable()
class MoodTrigger {
  final String moodName;
  final int tempo;
  final String? backgroundImageUrl;
  final String transitionType;
  final int timestamp;

  MoodTrigger({
    required this.moodName,
    required this.tempo,
    this.backgroundImageUrl,
    required this.transitionType,
    required this.timestamp,
  });

  factory MoodTrigger.fromJson(Map<String, dynamic> json) => _$MoodTriggerFromJson(json);
  Map<String, dynamic> toJson() => _$MoodTriggerToJson(this);
}