// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as int,
      creatorId: json['creator_id'] as int?,
      title: json['title'] as String,
      filepath: json['filepath'] as String,
      fileUrl: json['file_url'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'creator_id': instance.creatorId,
      'title': instance.title,
      'filepath': instance.filepath,
      'file_url': instance.fileUrl,
      'uploaded_at': instance.uploadedAt.toIso8601String(),
    };