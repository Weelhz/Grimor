import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/file_utils.dart';
import 'dart:convert';

class FileService {
  static FileService? _instance;
  static FileService get instance => _instance ??= FileService._();
  FileService._();

  late String _appDocumentsPath;
  late String _appCachePath;
  late String _appTempPath;
  bool _initialized = false;

  // Initialize the file service
  Future<void> initialize() async {
    if (_initialized) return;
    
    final documentsDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getApplicationCacheDirectory();
    final tempDir = await getTemporaryDirectory();
    
    _appDocumentsPath = documentsDir.path;
    _appCachePath = cacheDir.path;
    _appTempPath = tempDir.path;
    
    // Create necessary directories
    await _createDirectories();
    _initialized = true;
  }

  // Create app-specific directories
  Future<void> _createDirectories() async {
    final directories = [
      getBooksDirectory(),
      getMusicDirectory(),
      getBackgroundsDirectory(),
      getCacheDirectory(),
      getTempDirectory(),
    ];

    for (final dir in directories) {
      await FileUtils.ensureDirectoryExists(dir);
    }
  }

  // Get directory paths
  String getAppDocumentsPath() => _appDocumentsPath;
  String getAppCachePath() => _appCachePath;
  String getAppTempPath() => _appTempPath;

  String getBooksDirectory() => path.join(_appDocumentsPath, 'books');
  String getMusicDirectory() => path.join(_appDocumentsPath, 'music');
  String getBackgroundsDirectory() => path.join(_appDocumentsPath, 'backgrounds');
  String getCacheDirectory() => path.join(_appCachePath, 'book_sphere');
  String getTempDirectory() => path.join(_appTempPath, 'book_sphere');

  // Book file operations
  Future<File> saveBookFile(File sourceFile, String bookId) async {
    await _ensureInitialized();
    final booksDir = getBooksDirectory();
    final extension = FileUtils.getFileExtension(sourceFile.path);
    final filename = 'book_${bookId}$extension';
    final targetPath = path.join(booksDir, filename);
    
    return await FileUtils.copyFile(sourceFile, targetPath);
  }

  Future<File?> getBookFile(String bookId) async {
    await _ensureInitialized();
    final booksDir = getBooksDirectory();
    final supportedExtensions = FileUtils.supportedBookFormats;
    
    for (final ext in supportedExtensions) {
      final filePath = path.join(booksDir, 'book_$bookId$ext');
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
    }
    
    return null;
  }

  Future<void> deleteBookFile(String bookId) async {
    await _ensureInitialized();
    final file = await getBookFile(bookId);
    if (file != null) {
      await file.delete();
    }
  }

  // Music file operations
  Future<File> saveMusicFile(File sourceFile, String musicId) async {
    await _ensureInitialized();
    final musicDir = getMusicDirectory();
    final extension = FileUtils.getFileExtension(sourceFile.path);
    final filename = 'music_${musicId}$extension';
    final targetPath = path.join(musicDir, filename);
    
    return await FileUtils.copyFile(sourceFile, targetPath);
  }

  Future<File?> getMusicFile(String musicId) async {
    await _ensureInitialized();
    final musicDir = getMusicDirectory();
    final supportedExtensions = FileUtils.supportedMusicFormats;
    
    for (final ext in supportedExtensions) {
      final filePath = path.join(musicDir, 'music_$musicId$ext');
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
    }
    
    return null;
  }

  Future<void> deleteMusicFile(String musicId) async {
    await _ensureInitialized();
    final file = await getMusicFile(musicId);
    if (file != null) {
      await file.delete();
    }
  }

  // Background image operations
  Future<File> saveBackgroundFile(File sourceFile, String backgroundId) async {
    await _ensureInitialized();
    final backgroundsDir = getBackgroundsDirectory();
    final extension = FileUtils.getFileExtension(sourceFile.path);
    final filename = 'bg_${backgroundId}$extension';
    final targetPath = path.join(backgroundsDir, filename);
    
    return await FileUtils.copyFile(sourceFile, targetPath);
  }

  Future<File?> getBackgroundFile(String backgroundId) async {
    await _ensureInitialized();
    final backgroundsDir = getBackgroundsDirectory();
    final supportedExtensions = FileUtils.supportedImageFormats;
    
    for (final ext in supportedExtensions) {
      final filePath = path.join(backgroundsDir, 'bg_$backgroundId$ext');
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
    }
    
    return null;
  }

  Future<void> deleteBackgroundFile(String backgroundId) async {
    await _ensureInitialized();
    final file = await getBackgroundFile(backgroundId);
    if (file != null) {
      await file.delete();
    }
  }

  // Cache operations
  Future<File> saveToCacheWithId(String cacheId, Uint8List data) async {
    await _ensureInitialized();
    final cacheDir = getCacheDirectory();
    final filePath = path.join(cacheDir, cacheId);
    
    return await FileUtils.writeBytesToFile(data, filePath).then((_) => File(filePath));
  }

  Future<File> saveToCache(String url, Uint8List data) async {
    final cacheId = _generateCacheId(url);
    return await saveToCacheWithId(cacheId, data);
  }

  Future<File?> getCachedFile(String url) async {
    final cacheId = _generateCacheId(url);
    return await getCachedFileById(cacheId);
  }

  Future<File?> getCachedFileById(String cacheId) async {
    await _ensureInitialized();
    final cacheDir = getCacheDirectory();
    final filePath = path.join(cacheDir, cacheId);
    final file = File(filePath);
    
    if (await file.exists()) {
      return file;
    }
    
    return null;
  }

  Future<bool> isCached(String url) async {
    final cachedFile = await getCachedFile(url);
    return cachedFile != null;
  }

  Future<void> clearCache() async {
    await _ensureInitialized();
    final cacheDir = getCacheDirectory();
    await FileUtils.cleanupTempFiles(cacheDir);
  }

  Future<int> getCacheSize() async {
    await _ensureInitialized();
    final cacheDir = getCacheDirectory();
    return await FileUtils.getDirectorySize(cacheDir);
  }

  // Temporary file operations
  Future<File> createTempFile(String prefix, String extension) async {
    await _ensureInitialized();
    final tempDir = getTempDirectory();
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final filePath = path.join(tempDir, filename);
    
    final file = File(filePath);
    await file.create();
    return file;
  }

  Future<void> cleanupTempFiles() async {
    await _ensureInitialized();
    final tempDir = getTempDirectory();
    await FileUtils.cleanupTempFiles(tempDir);
  }

  // Asset download and caching
  Future<File> downloadAndCacheAsset(String url, String cacheId) async {
    await _ensureInitialized();
    // Check if already cached
    final cachedFile = await getCachedFileById(cacheId);
    if (cachedFile != null) {
      return cachedFile;
    }

    // Download the asset
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final data = await response.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        
        return await saveToCacheWithId(cacheId, Uint8List.fromList(data));
      } else {
        throw Exception('Failed to download asset: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  // Batch operations
  Future<List<File>> downloadAndCacheAssets(Map<String, String> urlToCacheId) async {
    final results = <File>[];
    
    for (final entry in urlToCacheId.entries) {
      try {
        final file = await downloadAndCacheAsset(entry.key, entry.value);
        results.add(file);
      } catch (e) {
        // Log error but continue with other assets
        print('Error downloading asset ${entry.key}: $e');
      }
    }
    
    return results;
  }

  // File validation
  Future<bool> validateFileIntegrity(File file, String expectedHash) async {
    try {
      final actualHash = await FileUtils.generateFileHash(file);
      return actualHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  // Get file info
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    final metadata = await FileUtils.getFileMetadata(file.path);
    return {
      'path': metadata.path,
      'name': metadata.name,
      'size': metadata.size,
      'sizeString': metadata.sizeString,
      'extension': metadata.extension,
      'modified': metadata.modified.toIso8601String(),
      'hash': await FileUtils.generateFileHash(file),
    };
  }

  // Storage usage
  Future<Map<String, dynamic>> getStorageUsage() async {
    await _ensureInitialized();
    final booksSize = await FileUtils.getDirectorySize(getBooksDirectory());
    final musicSize = await FileUtils.getDirectorySize(getMusicDirectory());
    final backgroundsSize = await FileUtils.getDirectorySize(getBackgroundsDirectory());
    final cacheSize = await FileUtils.getDirectorySize(getCacheDirectory());
    final tempSize = await FileUtils.getDirectorySize(getTempDirectory());
    
    final totalSize = booksSize + musicSize + backgroundsSize + cacheSize + tempSize;
    
    return {
      'books': booksSize,
      'music': musicSize,
      'backgrounds': backgroundsSize,
      'cache': cacheSize,
      'temp': tempSize,
      'total': totalSize,
      'booksString': FileUtils.getFileSizeString(booksSize),
      'musicString': FileUtils.getFileSizeString(musicSize),
      'backgroundsString': FileUtils.getFileSizeString(backgroundsSize),
      'cacheString': FileUtils.getFileSizeString(cacheSize),
      'tempString': FileUtils.getFileSizeString(tempSize),
      'totalString': FileUtils.getFileSizeString(totalSize),
    };
  }

  // Export/Import operations
  Future<File> exportData(String type, List<String> ids) async {
    await _ensureInitialized();
    final tempDir = getTempDirectory();
    final exportFile = await createTempFile('export_$type', '.json');
    
    final data = <String, dynamic>{
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'data': [],
    };
    
    // Export based on type
    switch (type) {
      case 'books':
        for (final id in ids) {
          final file = await getBookFile(id);
          if (file != null) {
            final info = await getFileInfo(file);
            data['data'].add(info);
          }
        }
        break;
      case 'music':
        for (final id in ids) {
          final file = await getMusicFile(id);
          if (file != null) {
            final info = await getFileInfo(file);
            data['data'].add(info);
          }
        }
        break;
    }
    
    await FileUtils.writeStringToFile(
      const JsonEncoder.withIndent('  ').convert(data),
      exportFile.path,
    );
    
    return exportFile;
  }

  // Helper methods
  String _generateCacheId(String url) {
    return url.hashCode.toString();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}

// File operation result wrapper
class FileOperationResult<T> {
  final bool success;
  final T? data;
  final String? error;

  FileOperationResult({
    required this.success,
    this.data,
    this.error,
  });

  factory FileOperationResult.success(T data) {
    return FileOperationResult(success: true, data: data);
  }

  factory FileOperationResult.error(String error) {
    return FileOperationResult(success: false, error: error);
  }
}

// File download progress callback
typedef FileDownloadProgressCallback = void Function(int received, int total);

// Enhanced file service with progress tracking
class EnhancedFileService extends FileService {
  Future<File> downloadAndCacheAssetWithProgress(
    String url,
    String cacheId,
    FileDownloadProgressCallback? onProgress,
  ) async {
    // Check if already cached
    final cachedFile = await getCachedFileById(cacheId);
    if (cachedFile != null) {
      return cachedFile;
    }

    // Download with progress tracking
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final contentLength = response.contentLength;
        final data = <int>[];
        
        await for (final chunk in response) {
          data.addAll(chunk);
          onProgress?.call(data.length, contentLength);
        }
        
        return await saveToCacheWithId(cacheId, Uint8List.fromList(data));
      } else {
        throw Exception('Failed to download asset: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
}