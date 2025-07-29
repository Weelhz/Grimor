import 'package:json_annotation/json_annotation.dart';

part 'music.g.dart';

@JsonSerializable()
class Music {
  final int id;
  final String title;
  final String? genre;
  final String filepath;
  final String fileUrl;
  final bool isPublic;
  final int initialTempo;

  Music({
    required this.id,
    required this.title,
    this.genre,
    required this.filepath,
    required this.fileUrl,
    required this.isPublic,
    required this.initialTempo,
  });

  factory Music.fromJson(Map<String, dynamic> json) => _$MusicFromJson(json);
  Map<String, dynamic> toJson() => _$MusicToJson(this);

  Music copyWith({
    int? id,
    String? title,
    String? genre,
    String? filepath,
    String? fileUrl,
    bool? isPublic,
    int? initialTempo,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      filepath: filepath ?? this.filepath,
      fileUrl: fileUrl ?? this.fileUrl,
      isPublic: isPublic ?? this.isPublic,
      initialTempo: initialTempo ?? this.initialTempo,
    );
  }
}