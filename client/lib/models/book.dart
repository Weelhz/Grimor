import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book {
  final int id;
  final int? creatorId;
  final String title;
  final String filepath;
  final String fileUrl;
  final DateTime uploadedAt;

  Book({
    required this.id,
    this.creatorId,
    required this.title,
    required this.filepath,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book copyWith({
    int? id,
    int? creatorId,
    String? title,
    String? filepath,
    String? fileUrl,
    DateTime? uploadedAt,
  }) {
    return Book(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      filepath: filepath ?? this.filepath,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}