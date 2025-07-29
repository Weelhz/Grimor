class Playlist {
  final int id;
  final int userId;
  final String name;
  final DateTime createdAt;
  final List<PlaylistTrack> tracks;

  Playlist({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      tracks: (json['tracks'] as List<dynamic>?)
          ?.map((track) => PlaylistTrack.fromJson(track))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'tracks': tracks.map((track) => track.toJson()).toList(),
    };
  }

  Playlist copyWith({
    int? id,
    int? userId,
    String? name,
    DateTime? createdAt,
    List<PlaylistTrack>? tracks,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      tracks: tracks ?? this.tracks,
    );
  }
}

class PlaylistTrack {
  final int id;
  final int playlistId;
  final int musicId;
  final int trackOrder;
  final Music? music; // Optional populated music data

  PlaylistTrack({
    required this.id,
    required this.playlistId,
    required this.musicId,
    required this.trackOrder,
    this.music,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) {
    return PlaylistTrack(
      id: json['id'],
      playlistId: json['playlist_id'],
      musicId: json['music_id'],
      trackOrder: json['track_order'],
      music: json['music'] != null ? Music.fromJson(json['music']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playlist_id': playlistId,
      'music_id': musicId,
      'track_order': trackOrder,
      if (music != null) 'music': music!.toJson(),
    };
  }

  PlaylistTrack copyWith({
    int? id,
    int? playlistId,
    int? musicId,
    int? trackOrder,
    Music? music,
  }) {
    return PlaylistTrack(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      musicId: musicId ?? this.musicId,
      trackOrder: trackOrder ?? this.trackOrder,
      music: music ?? this.music,
    );
  }
}

// Import music model
class Music {
  final int id;
  final String title;
  final String? genre;
  final String filepath;
  final bool isPublic;
  final int initialTempo;

  Music({
    required this.id,
    required this.title,
    this.genre,
    required this.filepath,
    required this.isPublic,
    required this.initialTempo,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'],
      title: json['title'],
      genre: json['genre'],
      filepath: json['filepath'],
      isPublic: json['is_public'] ?? true,
      initialTempo: json['initial_tempo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'genre': genre,
      'filepath': filepath,
      'is_public': isPublic,
      'initial_tempo': initialTempo,
    };
  }

  Music copyWith({
    int? id,
    String? title,
    String? genre,
    String? filepath,
    bool? isPublic,
    int? initialTempo,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      filepath: filepath ?? this.filepath,
      isPublic: isPublic ?? this.isPublic,
      initialTempo: initialTempo ?? this.initialTempo,
    );
  }
}