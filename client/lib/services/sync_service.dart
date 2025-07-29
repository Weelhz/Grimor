import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/sync_api.dart';
import '../models/sync.dart';
import '../models/book.dart';
import '../models/music.dart';
import '../models/mood.dart';
import '../storage/local_store.dart';
import 'file_service.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

  final SyncApi _syncApi = SyncApi();
  final LocalStore _localStore = LocalStore();
  final FileService _fileService = FileService.instance;

  // Sync state
  bool _isInitialized = false;
  bool _isSyncing = false;
  int _lastSyncVersion = 0;
  DateTime? _lastSyncTime;
  Timer? _syncTimer;

  // Offline queue
  final List<OfflineQueueItem> _offlineQueue = [];
  final StreamController<String> _syncStatusController = StreamController.broadcast();

  // Initialize sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadSyncState();
    _startPeriodicSync();
    _isInitialized = true;
  }

  // Load sync state from local storage
  Future<void> _loadSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncVersion = prefs.getInt('last_sync_version') ?? 0;
    
    final lastSyncString = prefs.getString('last_sync_time');
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.parse(lastSyncString);
    }

    // Load offline queue
    final queueJson = prefs.getString('offline_queue');
    if (queueJson != null) {
      final queueData = json.decode(queueJson) as List<dynamic>;
      _offlineQueue.clear();
      _offlineQueue.addAll(
        queueData.map((item) => OfflineQueueItem.fromJson(item)),
      );
    }
  }

  // Save sync state to local storage
  Future<void> _saveSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_version', _lastSyncVersion);
    
    if (_lastSyncTime != null) {
      await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
    }

    // Save offline queue
    final queueJson = json.encode(
      _offlineQueue.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('offline_queue', queueJson);
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_isSyncing) {
        performSync();
      }
    });
  }

  // Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Perform full sync
  Future<SyncResult> performSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        appliedChanges: [],
        conflicts: [],
        newVersion: _lastSyncVersion,
        error: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _syncStatusController.add('Syncing...');

    try {
      // Process offline queue first
      if (_offlineQueue.isNotEmpty) {
        await _processOfflineQueue();
      }

      // Get server delta
      final delta = await _syncApi.getSyncDelta(
        lastSyncTime: _lastSyncTime,
        lastSyncVersion: _lastSyncVersion,
      );

      // Apply server changes locally
      await _applyServerChanges(delta.changes);

      // Send local changes to server
      final localChanges = await _getLocalChanges();
      final result = await _syncApi.processSyncDelta(
        changes: localChanges,
        lastSyncVersion: _lastSyncVersion,
      );

      // Update sync state
      _lastSyncVersion = result.newVersion;
      _lastSyncTime = DateTime.now();
      await _saveSyncState();

      _syncStatusController.add('Sync completed');
      return result;

    } catch (e) {
      _syncStatusController.add('Sync failed: $e');
      return SyncResult(
        success: false,
        appliedChanges: [],
        conflicts: [],
        newVersion: _lastSyncVersion,
        error: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  // Process offline queue
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    try {
      final result = await _syncApi.processOfflineQueue(items: _offlineQueue);
      
      if (result.success) {
        _offlineQueue.clear();
        await _saveSyncState();
      }
    } catch (e) {
      // Log error but don't throw - we'll retry later
      print('Error processing offline queue: $e');
    }
  }

  // Apply server changes locally
  Future<void> _applyServerChanges(List<SyncChange> changes) async {
    for (final change in changes) {
      try {
        await _applyChange(change);
      } catch (e) {
        print('Error applying change ${change.id}: $e');
      }
    }
  }

  // Apply individual change
  Future<void> _applyChange(SyncChange change) async {
    switch (change.entityType) {
      case 'book':
        await _applyBookChange(change);
        break;
      case 'music':
        await _applyMusicChange(change);
        break;
      case 'mood':
        await _applyMoodChange(change);
        break;
      case 'reading_progress':
        await _applyReadingProgressChange(change);
        break;
      case 'user_settings':
        await _applyUserSettingsChange(change);
        break;
    }
  }

  // Apply book change
  Future<void> _applyBookChange(SyncChange change) async {
    switch (change.operationType) {
      case 'create':
      case 'update':
        final book = Book.fromJson(change.data);
        await _localStore.saveBook(book);
        break;
      case 'delete':
        final bookId = change.data['id'].toString();
        await _localStore.deleteBook(bookId);
        await _fileService.deleteBookFile(bookId);
        break;
    }
  }

  // Apply music change
  Future<void> _applyMusicChange(SyncChange change) async {
    switch (change.operationType) {
      case 'create':
      case 'update':
        final music = Music.fromJson(change.data);
        await _localStore.saveMusic(music);
        break;
      case 'delete':
        final musicId = change.data['id'].toString();
        await _localStore.deleteMusic(musicId);
        await _fileService.deleteMusicFile(musicId);
        break;
    }
  }

  // Apply mood change
  Future<void> _applyMoodChange(SyncChange change) async {
    switch (change.operationType) {
      case 'create':
      case 'update':
        final mood = MoodReference.fromJson(change.data);
        await _localStore.saveMoodReference(mood);
        break;
      case 'delete':
        final moodId = change.data['id'].toString();
        await _localStore.deleteMoodReference(moodId);
        break;
    }
  }

  // Apply reading progress change
  Future<void> _applyReadingProgressChange(SyncChange change) async {
    final progress = ReadingProgress.fromJson(change.data);
    await _localStore.saveReadingProgress(progress);
  }

  // Apply user settings change
  Future<void> _applyUserSettingsChange(SyncChange change) async {
    final settings = change.data;
    await _localStore.saveUserSettings(settings);
  }

  // Get local changes
  Future<List<SyncChange>> _getLocalChanges() async {
    final changes = <SyncChange>[];
    
    // Get pending changes from local store
    final pendingChanges = await _localStore.getPendingChanges();
    
    for (final change in pendingChanges) {
      changes.add(SyncChange(
        id: change['id'],
        entityType: change['entity_type'],
        operationType: change['operation_type'],
        data: change['data'],
        timestamp: DateTime.parse(change['timestamp']),
        version: change['version'],
      ));
    }
    
    return changes;
  }

  // Add item to offline queue
  Future<void> addToOfflineQueue({
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    final item = OfflineQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      entityType: entityType,
      data: data,
      timestamp: DateTime.now(),
    );

    _offlineQueue.add(item);
    await _saveSyncState();
  }

  // Sync reading progress
  Future<void> syncReadingProgress({
    required int bookId,
    required int presetId,
    required int chapter,
    required double pageFraction,
  }) async {
    try {
      await _syncApi.uploadReadingProgress(
        bookId: bookId,
        presetId: presetId,
        chapter: chapter,
        pageFraction: pageFraction,
      );
    } catch (e) {
      // Add to offline queue if sync fails
      await addToOfflineQueue(
        operation: 'update',
        entityType: 'reading_progress',
        data: {
          'book_id': bookId,
          'preset_id': presetId,
          'chapter': chapter,
          'page_fraction': pageFraction,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  // Sync user settings
  Future<void> syncUserSettings({
    String? theme,
    bool? dynamicBg,
    int? musicVolume,
    double? moodSensitivity,
  }) async {
    try {
      await _syncApi.syncUserSettings(
        theme: theme,
        dynamicBg: dynamicBg,
        musicVolume: musicVolume,
        moodSensitivity: moodSensitivity,
      );
    } catch (e) {
      // Add to offline queue if sync fails
      await addToOfflineQueue(
        operation: 'update',
        entityType: 'user_settings',
        data: {
          if (theme != null) 'theme': theme,
          if (dynamicBg != null) 'dynamic_bg': dynamicBg,
          if (musicVolume != null) 'music_volume': musicVolume,
          if (moodSensitivity != null) 'mood_sensitivity': moodSensitivity,
        },
      );
    }
  }

  // Preload book assets
  Future<void> preloadBookAssets({
    required int bookId,
    int? presetId,
    Function(double progress)? onProgress,
  }) async {
    _syncStatusController.add('Preloading assets...');
    
    try {
      // Get cache manifest
      final manifest = await _syncApi.getCacheManifest(
        bookId: bookId,
        presetId: presetId,
      );

      int downloadedCount = 0;
      final totalCount = manifest.assets.length;

      for (final asset in manifest.assets) {
        try {
          // Check if already cached
          final cachedFile = await _fileService.getCachedFileById(asset.id);
          if (cachedFile != null) {
            // Verify integrity
            final isValid = await _fileService.validateFileIntegrity(
              cachedFile,
              asset.hash,
            );
            if (isValid) {
              downloadedCount++;
              onProgress?.call(downloadedCount / totalCount);
              continue;
            }
          }

          // Download asset
          await _fileService.downloadAndCacheAsset(asset.url, asset.id);
          downloadedCount++;
          onProgress?.call(downloadedCount / totalCount);

        } catch (e) {
          print('Error downloading asset ${asset.id}: $e');
          if (asset.required) {
            throw Exception('Failed to download required asset: ${asset.id}');
          }
        }
      }

      // Report cache status
      await _syncApi.reportCacheStatus(
        bookId: bookId,
        cachedAssets: manifest.assets.map((a) => a.id).toList(),
        failedAssets: [],
      );

      _syncStatusController.add('Assets preloaded');

    } catch (e) {
      _syncStatusController.add('Asset preload failed: $e');
      rethrow;
    }
  }

  // Get sync stats
  Future<SyncStats> getSyncStats() async {
    try {
      return await _syncApi.getSyncStats();
    } catch (e) {
      // Return local stats if server unavailable
      return SyncStats(
        totalChanges: 0,
        pendingChanges: _offlineQueue.length,
        lastSyncTime: _lastSyncTime,
        lastSyncVersion: _lastSyncVersion,
        isOnline: false,
        cachedAssets: [],
        cacheSize: await _fileService.getCacheSize(),
      );
    }
  }

  // Clear sync data
  Future<void> clearSyncData() async {
    try {
      await _syncApi.clearSyncData();
      await _localStore.clearSyncData();
      await _fileService.clearCache();
      
      _lastSyncVersion = 0;
      _lastSyncTime = null;
      _offlineQueue.clear();
      
      await _saveSyncState();
      _syncStatusController.add('Sync data cleared');
      
    } catch (e) {
      _syncStatusController.add('Error clearing sync data: $e');
      rethrow;
    }
  }

  // Check sync health
  Future<SyncHealth> checkSyncHealth() async {
    try {
      return await _syncApi.checkSyncHealth();
    } catch (e) {
      return SyncHealth(
        isHealthy: false,
        issues: [e.toString()],
        lastCheck: DateTime.now(),
        syncVersion: _lastSyncVersion,
        canSync: false,
      );
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  int get lastSyncVersion => _lastSyncVersion;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<OfflineQueueItem> get offlineQueue => List.unmodifiable(_offlineQueue);
  Stream<String> get syncStatusStream => _syncStatusController.stream;

  // Dispose
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

// Sync conflict resolution
class SyncConflictResolver {
  static Future<SyncChange> resolveConflict(
    SyncConflict conflict,
    ConflictResolution resolution,
  ) async {
    switch (resolution) {
      case ConflictResolution.useLocal:
        return SyncChange(
          id: conflict.id,
          entityType: conflict.entityType,
          operationType: 'update',
          data: conflict.localData,
          timestamp: DateTime.now(),
          version: 0,
        );
      
      case ConflictResolution.useRemote:
        return SyncChange(
          id: conflict.id,
          entityType: conflict.entityType,
          operationType: 'update',
          data: conflict.remoteData,
          timestamp: DateTime.now(),
          version: 0,
        );
      
      case ConflictResolution.merge:
        final mergedData = _mergeData(conflict.localData, conflict.remoteData);
        return SyncChange(
          id: conflict.id,
          entityType: conflict.entityType,
          operationType: 'update',
          data: mergedData,
          timestamp: DateTime.now(),
          version: 0,
        );
    }
  }

  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(localData);
    
    // Simple merge strategy - prefer remote for most fields
    // but keep local timestamps for user actions
    for (final entry in remoteData.entries) {
      if (entry.key != 'last_read_time' && entry.key != 'local_modifications') {
        merged[entry.key] = entry.value;
      }
    }
    
    return merged;
  }
}

enum ConflictResolution { useLocal, useRemote, merge }

// Sync event types
class SyncEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

// Sync scheduler for background sync
class SyncScheduler {
  static SyncScheduler? _instance;
  static SyncScheduler get instance => _instance ??= SyncScheduler._();
  SyncScheduler._();

  final SyncService _syncService = SyncService.instance;
  Timer? _backgroundTimer;

  void startBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _syncService.performSync(),
    );
  }

  void stopBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  void scheduleImmediateSync() {
    Timer(const Duration(seconds: 5), () => _syncService.performSync());
  }
}