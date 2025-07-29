import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../models/sync.dart';

class SyncProvider with ChangeNotifier {
  final SyncService _syncService = SyncService.instance;
  
  // Connection state
  bool _isConnected = true;
  bool _isOfflineMode = false;
  
  // Sync state
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatus = 'Ready';
  
  // Pending changes
  int _pendingChangesCount = 0;
  bool _hasPendingChanges = false;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isOfflineMode => _isOfflineMode;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;
  int get pendingChangesCount => _pendingChangesCount;
  bool get hasPendingChanges => _hasPendingChanges;
  
  // Initialize sync provider
  Future<void> initialize() async {
    await _syncService.initialize();
    _listenToSyncStatus();
    await _updateSyncStats();
  }
  
  // Listen to sync status changes
  void _listenToSyncStatus() {
    _syncService.syncStatusStream.listen((status) {
      _syncStatus = status;
      _updateSyncState();
      notifyListeners();
    });
  }
  
  // Update sync statistics
  Future<void> _updateSyncStats() async {
    try {
      final stats = await _syncService.getSyncStats();
      _pendingChangesCount = stats.pendingChanges;
      _hasPendingChanges = stats.pendingChanges > 0;
      _isConnected = stats.isOnline;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }
  
  // Update sync state
  void _updateSyncState() {
    _isSyncing = _syncService.isSyncing;
    
    // Update progress based on sync status
    if (_syncStatus.contains('complete')) {
      _syncProgress = 1.0;
    } else if (_syncStatus.contains('failed')) {
      _syncProgress = 0.0;
    } else if (_isSyncing) {
      // Simulate progress for ongoing sync
      _syncProgress = 0.5;
    } else {
      _syncProgress = 0.0;
    }
  }
  
  // Perform manual sync
  Future<void> performSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatus = 'Syncing...';
    notifyListeners();
    
    try {
      final result = await _syncService.performSync();
      
      if (result.success) {
        _syncStatus = 'Sync completed';
        _syncProgress = 1.0;
        _isConnected = true;
        await _updateSyncStats();
      } else {
        _syncStatus = 'Sync failed: ${result.error}';
        _syncProgress = 0.0;
        _isConnected = false;
      }
    } catch (e) {
      _syncStatus = 'Sync failed: $e';
      _syncProgress = 0.0;
      _isConnected = false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  // Reconnect to server
  Future<void> reconnect() async {
    _syncStatus = 'Reconnecting...';
    notifyListeners();
    
    try {
      await performSync();
    } catch (e) {
      _syncStatus = 'Reconnection failed';
      _isConnected = false;
      notifyListeners();
    }
  }
  
  // Set offline mode
  void setOfflineMode(bool enabled) {
    _isOfflineMode = enabled;
    
    if (enabled) {
      _syncStatus = 'Offline mode enabled';
      _syncService.stopPeriodicSync();
    } else {
      _syncStatus = 'Online mode enabled';
      _syncService.performSync();
    }
    
    notifyListeners();
  }
  
  // Sync reading progress
  Future<void> syncReadingProgress({
    required int bookId,
    required int presetId,
    required int chapter,
    required double pageFraction,
  }) async {
    try {
      await _syncService.syncReadingProgress(
        bookId: bookId,
        presetId: presetId,
        chapter: chapter,
        pageFraction: pageFraction,
      );
      
      if (!_isOfflineMode) {
        await _updateSyncStats();
      }
    } catch (e) {
      // Add to offline queue
      _pendingChangesCount++;
      _hasPendingChanges = true;
      notifyListeners();
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
      await _syncService.syncUserSettings(
        theme: theme,
        dynamicBg: dynamicBg,
        musicVolume: musicVolume,
        moodSensitivity: moodSensitivity,
      );
      
      if (!_isOfflineMode) {
        await _updateSyncStats();
      }
    } catch (e) {
      // Add to offline queue
      _pendingChangesCount++;
      _hasPendingChanges = true;
      notifyListeners();
    }
  }
  
  // Preload book assets
  Future<void> preloadBookAssets({
    required int bookId,
    int? presetId,
    Function(double progress)? onProgress,
  }) async {
    try {
      await _syncService.preloadBookAssets(
        bookId: bookId,
        presetId: presetId,
        onProgress: onProgress,
      );
      
      _syncStatus = 'Assets preloaded';
      notifyListeners();
    } catch (e) {
      _syncStatus = 'Asset preload failed: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Get sync health
  Future<SyncHealth> getSyncHealth() async {
    return await _syncService.checkSyncHealth();
  }
  
  // Clear sync data
  Future<void> clearSyncData() async {
    try {
      await _syncService.clearSyncData();
      _pendingChangesCount = 0;
      _hasPendingChanges = false;
      _syncStatus = 'Sync data cleared';
      notifyListeners();
    } catch (e) {
      _syncStatus = 'Error clearing sync data: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Get offline queue
  List<OfflineQueueItem> get offlineQueue => _syncService.offlineQueue;
  
  // Force update sync stats
  Future<void> refreshSyncStats() async {
    await _updateSyncStats();
  }
  
  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}