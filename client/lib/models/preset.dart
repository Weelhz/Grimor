import 'package:json_annotation/json_annotation.dart';

part 'preset.g.dart';

@JsonSerializable()
class Preset {
  final int id;
  final int creatorId;
  final String presetName;
  final int bookId;
  final DateTime createdAt;
  final List<MoodMap>? moodMaps;

  Preset({
    required this.id,
    required this.creatorId,
    required this.presetName,
    required this.bookId,
    required this.createdAt,
    this.moodMaps,
  });

  factory Preset.fromJson(Map<String, dynamic> json) => _$PresetFromJson(json);
  Map<String, dynamic> toJson() => _$PresetToJson(this);
}

@JsonSerializable()
class MoodMap {
  final int id;
  final int presetId;
  final int chapter;
  final double pageFraction;
  final int? moodId;
  final int? backgroundId;
  final String transitionType;

  MoodMap({
    required this.id,
    required this.presetId,
    required this.chapter,
    required this.pageFraction,
    this.moodId,
    this.backgroundId,
    required this.transitionType,
  });

  factory MoodMap.fromJson(Map<String, dynamic> json) => _$MoodMapFromJson(json);
  Map<String, dynamic> toJson() => _$MoodMapToJson(this);
}