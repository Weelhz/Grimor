import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/music.dart';
import '../models/playlist.dart';
import '../storage/secure_store.dart';

class MusicApi {
  static const String baseUrl = 'http://localhost:3000/api';
  final SecureStore _secureStore = SecureStore();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStore.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all public music
  Future<List<Music>> getAllMusic() async {
    final response = await http.get(
      Uri.parse('$baseUrl/music'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> musicList = data['data'];
      return musicList.map((json) => Music.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load music: ${response.body}');
    }
  }

  // Get music by ID
  Future<Music> getMusicById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/music/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Music.fromJson(data['data']);
    } else {
      throw Exception('Failed to load music: ${response.body}');
    }
  }

  // Create new music (Creator only)
  Future<Music> createMusic({
    required String title,
    String? genre,
    required int initialTempo,
    bool isPublic = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/music'),
      headers: await _getHeaders(),
      body: json.encode({
        'title': title,
        'genre': genre,
        'initial_tempo': initialTempo,
        'is_public': isPublic,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Music.fromJson(data['data']);
    } else {
      throw Exception('Failed to create music: ${response.body}');
    }
  }

  // Upload music file
  Future<Music> uploadMusic({
    required File file,
    required String title,
    String? genre,
    required int initialTempo,
    bool isPublic = true,
  }) async {
    final token = await _secureStore.getAccessToken();
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/music/upload'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('music', file.path),
    );

    request.fields['title'] = title;
    request.fields['initial_tempo'] = initialTempo.toString();
    request.fields['is_public'] = isPublic.toString();
    if (genre != null) request.fields['genre'] = genre;

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final data = json.decode(responseBody);
      return Music.fromJson(data['data']);
    } else {
      throw Exception('Failed to upload music: $responseBody');
    }
  }

  // Update music
  Future<Music> updateMusic({
    required int id,
    String? title,
    String? genre,
    int? initialTempo,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (genre != null) body['genre'] = genre;
    if (initialTempo != null) body['initial_tempo'] = initialTempo;
    if (isPublic != null) body['is_public'] = isPublic;

    final response = await http.put(
      Uri.parse('$baseUrl/music/$id'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Music.fromJson(data['data']);
    } else {
      throw Exception('Failed to update music: ${response.body}');
    }
  }

  // Delete music
  Future<void> deleteMusic(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/music/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete music: ${response.body}');
    }
  }

  // Get user playlists
  Future<List<Playlist>> getUserPlaylists() async {
    final response = await http.get(
      Uri.parse('$baseUrl/playlists'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> playlists = data['data'];
      return playlists.map((json) => Playlist.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load playlists: ${response.body}');
    }
  }

  // Create playlist
  Future<Playlist> createPlaylist(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/playlists'),
      headers: await _getHeaders(),
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Playlist.fromJson(data['data']);
    } else {
      throw Exception('Failed to create playlist: ${response.body}');
    }
  }

  // Get playlist by ID with tracks
  Future<Playlist> getPlaylistById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/playlists/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Playlist.fromJson(data['data']);
    } else {
      throw Exception('Failed to load playlist: ${response.body}');
    }
  }

  // Update playlist
  Future<Playlist> updatePlaylist(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/playlists/$id'),
      headers: await _getHeaders(),
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Playlist.fromJson(data['data']);
    } else {
      throw Exception('Failed to update playlist: ${response.body}');
    }
  }

  // Delete playlist
  Future<void> deletePlaylist(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/playlists/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete playlist: ${response.body}');
    }
  }

  // Add track to playlist
  Future<void> addTrackToPlaylist(int playlistId, int musicId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks'),
      headers: await _getHeaders(),
      body: json.encode({'music_id': musicId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add track to playlist: ${response.body}');
    }
  }

  // Remove track from playlist
  Future<void> removeTrackFromPlaylist(int playlistId, int musicId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks/$musicId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove track from playlist: ${response.body}');
    }
  }

  // Search music
  Future<List<Music>> searchMusic(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/music/search?q=${Uri.encodeComponent(query)}'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> musicList = data['data'];
      return musicList.map((json) => Music.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search music: ${response.body}');
    }
  }

  // Get music by genre
  Future<List<Music>> getMusicByGenre(String genre) async {
    final response = await http.get(
      Uri.parse('$baseUrl/music/genre/${Uri.encodeComponent(genre)}'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> musicList = data['data'];
      return musicList.map((json) => Music.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load music by genre: ${response.body}');
    }
  }

  // Get signed URL for music file
  Future<String> getMusicSignedUrl(int musicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/music/$musicId/url'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    } else {
      throw Exception('Failed to get music URL: ${response.body}');
    }
  }
}