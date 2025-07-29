class SyncDelta {
  final List<SyncChange> changes;
  final int currentVersion;
  final DateTime timestamp;
  final bool hasMore;

  SyncDelta({
    required this.changes,
    required this.currentVersion,
    required this.timestamp,
    required this.hasMore,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      changes: (json['changes'] as List<dynamic>)
          .map((change) => SyncChange.fromJson(change))
          .toList(),
      currentVersion: json['current_version'],
      timestamp: DateTime.parse(json['timestamp']),
      hasMore: json['has_more'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'changes': changes.map((change) => change.toJson()).toList(),
      'current_version': currentVersion,
      'timestamp': timestamp.toIso8601String(),
      'has_more': hasMore,
    };
  }
}

class SyncChange {
  final String id;
  final String entityType;
  final String operationType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int version;

  SyncChange({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.data,
    required this.timestamp,
    required this.version,
  });

  factory SyncChange.fromJson(Map<String, dynamic> json) {
    return SyncChange(
      id: json['id'],
      entityType: json['entity_type'],
      operationType: json['operation_type'],
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'operation_type': operationType,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }
}

class SyncResult {
  final bool success;
  final List<String> appliedChanges;
  final List<SyncConflict> conflicts;
  final int newVersion;
  final String? error;

  SyncResult({
    required this.success,
    required this.appliedChanges,
    required this.conflicts,
    required this.newVersion,
    this.error,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'],
      appliedChanges: List<String>.from(json['applied_changes'] ?? []),
      conflicts: (json['conflicts'] as List<dynamic>?)
          ?.map((conflict) => SyncConflict.fromJson(conflict))
          .toList() ?? [],
      newVersion: json['new_version'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'applied_changes': appliedChanges,
      'conflicts': conflicts.map((conflict) => conflict.toJson()).toList(),
      'new_version': newVersion,
      'error': error,
    };
  }
}

class SyncConflict {
  final String id;
  final String entityType;
  final String conflictType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime timestamp;

  SyncConflict({
    required this.id,
    required this.entityType,
    required this.conflictType,
    required this.localData,
    required this.remoteData,
    required this.timestamp,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'],
      entityType: json['entity_type'],
      conflictType: json['conflict_type'],
      localData: json['local_data'] ?? {},
      remoteData: json['remote_data'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'conflict_type': conflictType,
      'local_data': localData,
      'remote_data': remoteData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SyncStats {
  final int totalChanges;
  final int pendingChanges;
  final DateTime? lastSyncTime;
  final int lastSyncVersion;
  final bool isOnline;
  final List<String> cachedAssets;
  final int cacheSize;

  SyncStats({
    required this.totalChanges,
    required this.pendingChanges,
    this.lastSyncTime,
    required this.lastSyncVersion,
    required this.isOnline,
    required this.cachedAssets,
    required this.cacheSize,
  });

  factory SyncStats.fromJson(Map<String, dynamic> json) {
    return SyncStats(
      totalChanges: json['total_changes'],
      pendingChanges: json['pending_changes'],
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'])
          : null,
      lastSyncVersion: json['last_sync_version'],
      isOnline: json['is_online'] ?? false,
      cachedAssets: List<String>.from(json['cached_assets'] ?? []),
      cacheSize: json['cache_size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_changes': totalChanges,
      'pending_changes': pendingChanges,
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'last_sync_version': lastSyncVersion,
      'is_online': isOnline,
      'cached_assets': cachedAssets,
      'cache_size': cacheSize,
    };
  }
}

class ReadingProgress {
  final int bookId;
  final int? presetId;
  final int chapter;
  final double pageFraction;
  final DateTime timestamp;

  ReadingProgress({
    required this.bookId,
    this.presetId,
    required this.chapter,
    required this.pageFraction,
    required this.timestamp,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      bookId: json['book_id'],
      presetId: json['preset_id'],
      chapter: json['chapter'],
      pageFraction: json['page_fraction'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'preset_id': presetId,
      'chapter': chapter,
      'page_fraction': pageFraction,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class CacheManifest {
  final int bookId;
  final List<CacheAsset> assets;
  final int totalSize;
  final DateTime timestamp;

  CacheManifest({
    required this.bookId,
    required this.assets,
    required this.totalSize,
    required this.timestamp,
  });

  factory CacheManifest.fromJson(Map<String, dynamic> json) {
    return CacheManifest(
      bookId: json['book_id'],
      assets: (json['assets'] as List<dynamic>)
          .map((asset) => CacheAsset.fromJson(asset))
          .toList(),
      totalSize: json['total_size'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'assets': assets.map((asset) => asset.toJson()).toList(),
      'total_size': totalSize,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class CacheAsset {
  final String id;
  final String type;
  final String url;
  final int size;
  final String hash;
  final bool required;

  CacheAsset({
    required this.id,
    required this.type,
    required this.url,
    required this.size,
    required this.hash,
    required this.required,
  });

  factory CacheAsset.fromJson(Map<String, dynamic> json) {
    return CacheAsset(
      id: json['id'],
      type: json['type'],
      url: json['url'],
      size: json['size'],
      hash: json['hash'],
      required: json['required'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'size': size,
      'hash': hash,
      'required': required,
    };
  }
}

class OfflineQueueItem {
  final String id;
  final String operation;
  final String entityType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  OfflineQueueItem({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'],
      operation: json['operation'],
      entityType: json['entity_type'],
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retry_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'entity_type': entityType,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
    };
  }
}

class SyncHealth {
  final bool isHealthy;
  final List<String> issues;
  final DateTime lastCheck;
  final int syncVersion;
  final bool canSync;

  SyncHealth({
    required this.isHealthy,
    required this.issues,
    required this.lastCheck,
    required this.syncVersion,
    required this.canSync,
  });

  factory SyncHealth.fromJson(Map<String, dynamic> json) {
    return SyncHealth(
      isHealthy: json['is_healthy'],
      issues: List<String>.from(json['issues'] ?? []),
      lastCheck: DateTime.parse(json['last_check']),
      syncVersion: json['sync_version'],
      canSync: json['can_sync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_healthy': isHealthy,
      'issues': issues,
      'last_check': lastCheck.toIso8601String(),
      'sync_version': syncVersion,
      'can_sync': canSync,
    };
  }
}