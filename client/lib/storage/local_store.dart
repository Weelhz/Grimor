import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/music.dart';
import '../models/mood.dart';
import '../models/playlist.dart';
import '../models/sync.dart';

class LocalStore {
  static Database? _database;
  static const String _databaseName = 'book_sphere.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Books table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        filepath TEXT NOT NULL,
        creator_id INTEGER,
        uploaded_at TEXT NOT NULL,
        cached_at TEXT,
        is_cached INTEGER DEFAULT 0,
        file_size INTEGER DEFAULT 0,
        last_read_at TEXT,
        reading_progress TEXT
      )
    ''');

    // Music table
    await db.execute('''
      CREATE TABLE music (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        genre TEXT,
        filepath TEXT NOT NULL,
        is_public INTEGER DEFAULT 1,
        initial_tempo INTEGER NOT NULL,
        cached_at TEXT,
        is_cached INTEGER DEFAULT 0,
        file_size INTEGER DEFAULT 0
      )
    ''');

    // Mood references table
    await db.execute('''
      CREATE TABLE mood_references (
        id INTEGER PRIMARY KEY,
        mood_name TEXT UNIQUE NOT NULL,
        tempo_electronic INTEGER NOT NULL,
        tempo_classic INTEGER NOT NULL,
        tempo_lofi INTEGER NOT NULL,
        tempo_custom INTEGER DEFAULT 0
      )
    ''');

    // Mood backgrounds table
    await db.execute('''
      CREATE TABLE mood_backgrounds (
        id INTEGER PRIMARY KEY,
        mood_id INTEGER NOT NULL,
        background_path TEXT NOT NULL,
        cached_at TEXT,
        is_cached INTEGER DEFAULT 0,
        FOREIGN KEY (mood_id) REFERENCES mood_references (id)
      )
    ''');

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Playlist tracks table
    await db.execute('''
      CREATE TABLE playlist_tracks (
        id INTEGER PRIMARY KEY,
        playlist_id INTEGER NOT NULL,
        music_id INTEGER NOT NULL,
        track_order INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id),
        FOREIGN KEY (music_id) REFERENCES music (id)
      )
    ''');

    // Reading progress table
    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY,
        book_id INTEGER NOT NULL,
        preset_id INTEGER,
        chapter INTEGER NOT NULL,
        page_fraction REAL NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (book_id) REFERENCES books (id)
      )
    ''');

    // Sync changes table
    await db.execute('''
      CREATE TABLE sync_changes (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        version INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Cache metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        accessed_at TEXT NOT NULL,
        expires_at TEXT
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_books_creator_id ON books(creator_id)');
    await db.execute('CREATE INDEX idx_music_genre ON music(genre)');
    await db.execute('CREATE INDEX idx_playlist_tracks_playlist_id ON playlist_tracks(playlist_id)');
    await db.execute('CREATE INDEX idx_reading_progress_book_id ON reading_progress(book_id)');
    await db.execute('CREATE INDEX idx_sync_changes_entity_type ON sync_changes(entity_type)');
    await db.execute('CREATE INDEX idx_sync_changes_synced ON sync_changes(synced)');
  }

  // Book operations
  Future<void> saveBook(Book book) async {
    final db = await database;
    await db.insert(
      'books',
      {
        'id': book.id,
        'title': book.title,
        'filepath': book.filepath,
        'creator_id': book.creatorId,
        'uploaded_at': book.uploadedAt.toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
        'is_cached': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Book?> getBook(String id) async {
    final db = await database;
    final result = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    return Book(
      id: row['id'] as int,
      title: row['title'] as String,
      filepath: row['filepath'] as String,
      creatorId: row['creator_id'] as int?,
      uploadedAt: DateTime.parse(row['uploaded_at'] as String),
    );
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final result = await db.query('books', orderBy: 'uploaded_at DESC');
    
    return result.map((row) => Book(
      id: row['id'] as int,
      title: row['title'] as String,
      filepath: row['filepath'] as String,
      creatorId: row['creator_id'] as int?,
      uploadedAt: DateTime.parse(row['uploaded_at'] as String),
    )).toList();
  }

  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Music operations
  Future<void> saveMusic(Music music) async {
    final db = await database;
    await db.insert(
      'music',
      {
        'id': music.id,
        'title': music.title,
        'genre': music.genre,
        'filepath': music.filepath,
        'is_public': music.isPublic ? 1 : 0,
        'initial_tempo': music.initialTempo,
        'cached_at': DateTime.now().toIso8601String(),
        'is_cached': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Music?> getMusic(String id) async {
    final db = await database;
    final result = await db.query(
      'music',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    return Music(
      id: row['id'] as int,
      title: row['title'] as String,
      genre: row['genre'] as String?,
      filepath: row['filepath'] as String,
      isPublic: (row['is_public'] as int) == 1,
      initialTempo: row['initial_tempo'] as int,
    );
  }

  Future<List<Music>> getAllMusic() async {
    final db = await database;
    final result = await db.query('music', orderBy: 'title ASC');
    
    return result.map((row) => Music(
      id: row['id'] as int,
      title: row['title'] as String,
      genre: row['genre'] as String?,
      filepath: row['filepath'] as String,
      isPublic: (row['is_public'] as int) == 1,
      initialTempo: row['initial_tempo'] as int,
    )).toList();
  }

  Future<void> deleteMusic(String id) async {
    final db = await database;
    await db.delete('music', where: 'id = ?', whereArgs: [id]);
  }

  // Mood operations
  Future<void> saveMoodReference(MoodReference mood) async {
    final db = await database;
    await db.insert(
      'mood_references',
      {
        'id': mood.id,
        'mood_name': mood.moodName,
        'tempo_electronic': mood.tempoElectronic,
        'tempo_classic': mood.tempoClassic,
        'tempo_lofi': mood.tempoLofi,
        'tempo_custom': mood.tempoCustom,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MoodReference?> getMoodReference(String id) async {
    final db = await database;
    final result = await db.query(
      'mood_references',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    return MoodReference(
      id: row['id'] as int,
      moodName: row['mood_name'] as String,
      tempoElectronic: row['tempo_electronic'] as int,
      tempoClassic: row['tempo_classic'] as int,
      tempoLofi: row['tempo_lofi'] as int,
      tempoCustom: row['tempo_custom'] as int,
    );
  }

  Future<List<MoodReference>> getAllMoodReferences() async {
    final db = await database;
    final result = await db.query('mood_references', orderBy: 'mood_name ASC');
    
    return result.map((row) => MoodReference(
      id: row['id'] as int,
      moodName: row['mood_name'] as String,
      tempoElectronic: row['tempo_electronic'] as int,
      tempoClassic: row['tempo_classic'] as int,
      tempoLofi: row['tempo_lofi'] as int,
      tempoCustom: row['tempo_custom'] as int,
    )).toList();
  }

  Future<void> deleteMoodReference(String id) async {
    final db = await database;
    await db.delete('mood_references', where: 'id = ?', whereArgs: [id]);
  }

  // Reading progress operations
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'book_id': progress.bookId,
        'preset_id': progress.presetId,
        'chapter': progress.chapter,
        'page_fraction': progress.pageFraction,
        'timestamp': progress.timestamp.toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReadingProgress?> getLatestReadingProgress(int bookId) async {
    final db = await database;
    final result = await db.query(
      'reading_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    return ReadingProgress(
      bookId: row['book_id'] as int,
      presetId: row['preset_id'] as int?,
      chapter: row['chapter'] as int,
      pageFraction: row['page_fraction'] as double,
      timestamp: DateTime.parse(row['timestamp'] as String),
    );
  }

  // Sync operations
  Future<void> addSyncChange(SyncChange change) async {
    final db = await database;
    await db.insert(
      'sync_changes',
      {
        'id': change.id,
        'entity_type': change.entityType,
        'operation_type': change.operationType,
        'data': json.encode(change.data),
        'timestamp': change.timestamp.toIso8601String(),
        'version': change.version,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    final db = await database;
    final result = await db.query(
      'sync_changes',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    
    return result.map((row) => {
      'id': row['id'],
      'entity_type': row['entity_type'],
      'operation_type': row['operation_type'],
      'data': json.decode(row['data'] as String),
      'timestamp': row['timestamp'],
      'version': row['version'],
    }).toList();
  }

  Future<void> markChangesSynced(List<String> changeIds) async {
    final db = await database;
    for (final id in changeIds) {
      await db.update(
        'sync_changes',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // User settings operations
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final db = await database;
    for (final entry in settings.entries) {
      await db.insert(
        'user_settings',
        {
          'key': entry.key,
          'value': json.encode(entry.value),
          'updated_at': DateTime.now().toIso8601String(),
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>> getUserSettings() async {
    final db = await database;
    final result = await db.query('user_settings');
    
    final settings = <String, dynamic>{};
    for (final row in result) {
      settings[row['key'] as String] = json.decode(row['value'] as String);
    }
    
    return settings;
  }

  // Cache metadata operations
  Future<void> saveCacheMetadata({
    required String id,
    required String url,
    required String filePath,
    required int fileSize,
    required String hash,
    DateTime? expiresAt,
  }) async {
    final db = await database;
    final now = DateTime.now();
    
    await db.insert(
      'cache_metadata',
      {
        'id': id,
        'url': url,
        'file_path': filePath,
        'file_size': fileSize,
        'hash': hash,
        'created_at': now.toIso8601String(),
        'accessed_at': now.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCacheMetadata(String id) async {
    final db = await database;
    final result = await db.query(
      'cache_metadata',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    
    // Update accessed_at
    await db.update(
      'cache_metadata',
      {'accessed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return {
      'id': row['id'],
      'url': row['url'],
      'file_path': row['file_path'],
      'file_size': row['file_size'],
      'hash': row['hash'],
      'created_at': DateTime.parse(row['created_at'] as String),
      'accessed_at': DateTime.parse(row['accessed_at'] as String),
      'expires_at': row['expires_at'] != null 
          ? DateTime.parse(row['expires_at'] as String)
          : null,
    };
  }

  Future<void> deleteCacheMetadata(String id) async {
    final db = await database;
    await db.delete('cache_metadata', where: 'id = ?', whereArgs: [id]);
  }

  // Cleanup operations
  Future<void> cleanupExpiredCache() async {
    final db = await database;
    final now = DateTime.now();
    
    await db.delete(
      'cache_metadata',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [now.toIso8601String()],
    );
  }

  Future<void> clearSyncData() async {
    final db = await database;
    await db.delete('sync_changes');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('books');
    await db.delete('music');
    await db.delete('mood_references');
    await db.delete('mood_backgrounds');
    await db.delete('playlists');
    await db.delete('playlist_tracks');
    await db.delete('reading_progress');
    await db.delete('sync_changes');
    await db.delete('user_settings');
    await db.delete('cache_metadata');
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    final db = await database;
    
    final bookCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books'),
    ) ?? 0;
    
    final musicCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM music'),
    ) ?? 0;
    
    final cacheCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cache_metadata'),
    ) ?? 0;
    
    final pendingChanges = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_changes WHERE synced = 0'),
    ) ?? 0;
    
    return {
      'books': bookCount,
      'music': musicCount,
      'cached_items': cacheCount,
      'pending_changes': pendingChanges,
    };
  }
}