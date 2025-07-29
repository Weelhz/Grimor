// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Music _$MusicFromJson(Map<String, dynamic> json) => Music(
      id: json['id'] as int,
      title: json['title'] as String,
      genre: json['genre'] as String?,
      filepath: json['filepath'] as String,
      fileUrl: json['file_url'] as String,
      isPublic: json['is_public'] as bool,
      initialTempo: json['initial_tempo'] as int,
    );

Map<String, dynamic> _$MusicToJson(Music instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'genre': instance.genre,
      'filepath': instance.filepath,
      'file_url': instance.fileUrl,
      'is_public': instance.isPublic,
      'initial_tempo': instance.initialTempo,
    };