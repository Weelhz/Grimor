import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sync.dart';
import '../storage/secure_store.dart';

class SyncApi {
  static const String baseUrl = 'http://localhost:3000/api';
  final SecureStore _secureStore = SecureStore();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStore.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get sync delta (changes since last sync)
  Future<SyncDelta> getSyncDelta({
    DateTime? lastSyncTime,
    int? lastSyncVersion,
  }) async {
    final queryParams = <String, String>{};
    if (lastSyncTime != null) {
      queryParams['last_sync_time'] = lastSyncTime.toIso8601String();
    }
    if (lastSyncVersion != null) {
      queryParams['last_sync_version'] = lastSyncVersion.toString();
    }

    final uri = Uri.parse('$baseUrl/sync/delta').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SyncDelta.fromJson(data['data']);
    } else {
      throw Exception('Failed to get sync delta: ${response.body}');
    }
  }

  // Process sync delta (send local changes to server)
  Future<SyncResult> processSyncDelta({
    required List<SyncChange> changes,
    int? lastSyncVersion,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/delta'),
      headers: await _getHeaders(),
      body: json.encode({
        'changes': changes.map((c) => c.toJson()).toList(),
        'last_sync_version': lastSyncVersion,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SyncResult.fromJson(data['data']);
    } else {
      throw Exception('Failed to process sync delta: ${response.body}');
    }
  }

  // Get sync stats
  Future<SyncStats> getSyncStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SyncStats.fromJson(data['data']);
    } else {
      throw Exception('Failed to get sync stats: ${response.body}');
    }
  }

  // Clear sync data (reset sync state)
  Future<void> clearSyncData() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sync/clear'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear sync data: ${response.body}');
    }
  }

  // Upload reading progress
  Future<void> uploadReadingProgress({
    required int bookId,
    required int presetId,
    required int chapter,
    required double pageFraction,
    DateTime? timestamp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/progress'),
      headers: await _getHeaders(),
      body: json.encode({
        'book_id': bookId,
        'preset_id': presetId,
        'chapter': chapter,
        'page_fraction': pageFraction,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload reading progress: ${response.body}');
    }
  }

  // Get reading progress
  Future<ReadingProgress?> getReadingProgress({
    required int bookId,
    int? presetId,
  }) async {
    final queryParams = <String, String>{
      'book_id': bookId.toString(),
      if (presetId != null) 'preset_id': presetId.toString(),
    };

    final uri = Uri.parse('$baseUrl/sync/progress').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return ReadingProgress.fromJson(data['data']);
      }
      return null;
    } else {
      throw Exception('Failed to get reading progress: ${response.body}');
    }
  }

  // Sync user settings
  Future<void> syncUserSettings({
    String? theme,
    bool? dynamicBg,
    int? musicVolume,
    double? moodSensitivity,
  }) async {
    final body = <String, dynamic>{};
    if (theme != null) body['theme'] = theme;
    if (dynamicBg != null) body['dynamic_bg'] = dynamicBg;
    if (musicVolume != null) body['music_volume'] = musicVolume;
    if (moodSensitivity != null) body['mood_sensitivity'] = moodSensitivity;

    final response = await http.post(
      Uri.parse('$baseUrl/sync/settings'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync user settings: ${response.body}');
    }
  }

  // Get cache manifest (list of assets to cache)
  Future<CacheManifest> getCacheManifest({
    required int bookId,
    int? presetId,
  }) async {
    final queryParams = <String, String>{
      'book_id': bookId.toString(),
      if (presetId != null) 'preset_id': presetId.toString(),
    };

    final uri = Uri.parse('$baseUrl/sync/cache-manifest').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CacheManifest.fromJson(data['data']);
    } else {
      throw Exception('Failed to get cache manifest: ${response.body}');
    }
  }

  // Report asset cache status
  Future<void> reportCacheStatus({
    required int bookId,
    required List<String> cachedAssets,
    required List<String> failedAssets,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/cache-status'),
      headers: await _getHeaders(),
      body: json.encode({
        'book_id': bookId,
        'cached_assets': cachedAssets,
        'failed_assets': failedAssets,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to report cache status: ${response.body}');
    }
  }

  // Get offline queue (pending sync items)
  Future<List<OfflineQueueItem>> getOfflineQueue() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/offline-queue'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['data'];
      return items.map((json) => OfflineQueueItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get offline queue: ${response.body}');
    }
  }

  // Process offline queue (sync pending items)
  Future<SyncResult> processOfflineQueue({
    required List<OfflineQueueItem> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/offline-queue'),
      headers: await _getHeaders(),
      body: json.encode({
        'items': items.map((item) => item.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SyncResult.fromJson(data['data']);
    } else {
      throw Exception('Failed to process offline queue: ${response.body}');
    }
  }

  // Check sync health
  Future<SyncHealth> checkSyncHealth() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/health'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SyncHealth.fromJson(data['data']);
    } else {
      throw Exception('Failed to check sync health: ${response.body}');
    }
  }
}