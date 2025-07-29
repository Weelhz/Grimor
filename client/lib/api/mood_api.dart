import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/mood.dart';
import '../storage/secure_store.dart';

class MoodApi {
  static const String baseUrl = 'http://localhost:5000/api';
  final SecureStore _secureStore = SecureStore();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStore.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all mood references
  Future<List<MoodReference>> getAllMoods() async {
    final response = await http.get(
      Uri.parse('$baseUrl/moods'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> moods = data['data'];
      return moods.map((json) => MoodReference.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load moods: ${response.body}');
    }
  }

  // Get mood reference by ID
  Future<MoodReference> getMoodById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/moods/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MoodReference.fromJson(data['data']);
    } else {
      throw Exception('Failed to load mood: ${response.body}');
    }
  }

  // Create mood reference (Creator only)
  Future<MoodReference> createMood({
    required String moodName,
    required int tempoElectronic,
    required int tempoClassic,
    required int tempoLofi,
    int tempoCustom = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/moods'),
      headers: await _getHeaders(),
      body: json.encode({
        'mood_name': moodName,
        'tempo_electronic': tempoElectronic,
        'tempo_classic': tempoClassic,
        'tempo_lofi': tempoLofi,
        'tempo_custom': tempoCustom,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return MoodReference.fromJson(data['data']);
    } else {
      throw Exception('Failed to create mood: ${response.body}');
    }
  }

  // Update mood reference
  Future<MoodReference> updateMood({
    required int id,
    String? moodName,
    int? tempoElectronic,
    int? tempoClassic,
    int? tempoLofi,
    int? tempoCustom,
  }) async {
    final body = <String, dynamic>{};
    if (moodName != null) body['mood_name'] = moodName;
    if (tempoElectronic != null) body['tempo_electronic'] = tempoElectronic;
    if (tempoClassic != null) body['tempo_classic'] = tempoClassic;
    if (tempoLofi != null) body['tempo_lofi'] = tempoLofi;
    if (tempoCustom != null) body['tempo_custom'] = tempoCustom;

    final response = await http.put(
      Uri.parse('$baseUrl/moods/$id'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MoodReference.fromJson(data['data']);
    } else {
      throw Exception('Failed to update mood: ${response.body}');
    }
  }

  // Delete mood reference
  Future<void> deleteMood(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/moods/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete mood: ${response.body}');
    }
  }

  // Get mood backgrounds
  Future<List<MoodBackground>> getMoodBackgrounds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/moods/backgrounds'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> backgrounds = data['data'];
      return backgrounds.map((json) => MoodBackground.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load mood backgrounds: ${response.body}');
    }
  }

  // Create mood background
  Future<MoodBackground> createMoodBackground({
    required int moodId,
    required File backgroundFile,
  }) async {
    final token = await _secureStore.getAccessToken();
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/moods/backgrounds'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('background', backgroundFile.path),
    );

    request.fields['mood_id'] = moodId.toString();

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final data = json.decode(responseBody);
      return MoodBackground.fromJson(data['data']);
    } else {
      throw Exception('Failed to create mood background: $responseBody');
    }
  }

  // Get mood backgrounds by mood ID
  Future<List<MoodBackground>> getMoodBackgroundsByMoodId(int moodId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/moods/$moodId/backgrounds'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> backgrounds = data['data'];
      return backgrounds.map((json) => MoodBackground.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load mood backgrounds: ${response.body}');
    }
  }

  // Delete mood background
  Future<void> deleteMoodBackground(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/moods/backgrounds/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete mood background: ${response.body}');
    }
  }

  // Get signed URL for background image
  Future<String> getBackgroundSignedUrl(int backgroundId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/moods/backgrounds/$backgroundId/url'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    } else {
      throw Exception('Failed to get background URL: ${response.body}');
    }
  }

  // Get mood map for preset
  Future<List<MoodMap>> getMoodMapForPreset(int presetId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/presets/$presetId/moodmaps'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> moodMaps = data['data'];
      return moodMaps.map((json) => MoodMap.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load mood map: ${response.body}');
    }
  }

  // Create mood map entry
  Future<MoodMap> createMoodMap({
    required int presetId,
    required int chapter,
    required double pageFraction,
    int? moodId,
    int? backgroundId,
    String transitionType = 'fade',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/presets/$presetId/moodmaps'),
      headers: await _getHeaders(),
      body: json.encode({
        'chapter': chapter,
        'page_fraction': pageFraction,
        'mood_id': moodId,
        'background_id': backgroundId,
        'transition_type': transitionType,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return MoodMap.fromJson(data['data']);
    } else {
      throw Exception('Failed to create mood map: ${response.body}');
    }
  }

  // Update mood map entry
  Future<MoodMap> updateMoodMap({
    required int presetId,
    required int moodMapId,
    int? chapter,
    double? pageFraction,
    int? moodId,
    int? backgroundId,
    String? transitionType,
  }) async {
    final body = <String, dynamic>{};
    if (chapter != null) body['chapter'] = chapter;
    if (pageFraction != null) body['page_fraction'] = pageFraction;
    if (moodId != null) body['mood_id'] = moodId;
    if (backgroundId != null) body['background_id'] = backgroundId;
    if (transitionType != null) body['transition_type'] = transitionType;

    final response = await http.put(
      Uri.parse('$baseUrl/presets/$presetId/moodmaps/$moodMapId'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MoodMap.fromJson(data['data']);
    } else {
      throw Exception('Failed to update mood map: ${response.body}');
    }
  }

  // Delete mood map entry
  Future<void> deleteMoodMap(int presetId, int moodMapId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/presets/$presetId/moodmaps/$moodMapId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete mood map: ${response.body}');
    }
  }

  // Get mood trigger for current progress
  Future<MoodTrigger?> getMoodTrigger({
    required int presetId,
    required int chapter,
    required double pageFraction,
    required double sensitivity,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/presets/$presetId/moodtrigger'
          '?chapter=$chapter&page_fraction=$pageFraction&sensitivity=$sensitivity'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return MoodTrigger.fromJson(data['data']);
      }
      return null;
    } else {
      throw Exception('Failed to get mood trigger: ${response.body}');
    }
  }
}