import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CacheService {
  final Logger _logger = Logger();
  late Directory _cacheDirectory;

  Future<void> initialize() async {
    _cacheDirectory = await getApplicationDocumentsDirectory();
    await _ensureDirectoryExists('books');
    await _ensureDirectoryExists('music');
    await _ensureDirectoryExists('backgrounds');
  }

  Future<void> _ensureDirectoryExists(String subDir) async {
    final dir = Directory('${_cacheDirectory.path}/$subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  // Book caching
  Future<String?> cacheBook(String bookId, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File('${_cacheDirectory.path}/books/$bookId.pdf');
        await file.writeAsBytes(response.bodyBytes);
        _logger.i('Book cached: $bookId');
        return file.path;
      }
    } catch (e) {
      _logger.e('Failed to cache book $bookId: $e');
    }
    return null;
  }

  Future<String?> getCachedBookPath(String bookId) async {
    final file = File('${_cacheDirectory.path}/books/$bookId.pdf');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  // Music caching
  Future<String?> cacheMusic(String musicId, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File('${_cacheDirectory.path}/music/$musicId.mp3');
        await file.writeAsBytes(response.bodyBytes);
        _logger.i('Music cached: $musicId');
        return file.path;
      }
    } catch (e) {
      _logger.e('Failed to cache music $musicId: $e');
    }
    return null;
  }

  Future<String?> getCachedMusicPath(String musicId) async {
    final file = File('${_cacheDirectory.path}/music/$musicId.mp3');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  // Background caching
  Future<String?> cacheBackground(String backgroundId, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File('${_cacheDirectory.path}/backgrounds/$backgroundId.jpg');
        await file.writeAsBytes(response.bodyBytes);
        _logger.i('Background cached: $backgroundId');
        return file.path;
      }
    } catch (e) {
      _logger.e('Failed to cache background $backgroundId: $e');
    }
    return null;
  }

  Future<String?> getCachedBackgroundPath(String backgroundId) async {
    final file = File('${_cacheDirectory.path}/backgrounds/$backgroundId.jpg');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  // Cache management
  Future<void> clearCache() async {
    try {
      await _clearDirectory('books');
      await _clearDirectory('music');
      await _clearDirectory('backgrounds');
      _logger.i('Cache cleared');
    } catch (e) {
      _logger.e('Failed to clear cache: $e');
    }
  }

  Future<void> _clearDirectory(String subDir) async {
    final dir = Directory('${_cacheDirectory.path}/$subDir');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  Future<int> getCacheSize() async {
    int totalSize = 0;
    final dirs = ['books', 'music', 'backgrounds'];
    
    for (final dirName in dirs) {
      final dir = Directory('${_cacheDirectory.path}/$dirName');
      if (await dir.exists()) {
        await for (final file in dir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
    }
    
    return totalSize;
  }

  // Preload assets for a book
  Future<Map<String, String>> preloadBookAssets(
    String bookId,
    String bookUrl,
    List<String> musicUrls,
    List<String> backgroundUrls,
  ) async {
    final Map<String, String> cachedPaths = {};
    
    // Cache book
    final bookPath = await cacheBook(bookId, bookUrl);
    if (bookPath != null) {
      cachedPaths['book'] = bookPath;
    }
    
    // Cache music
    for (int i = 0; i < musicUrls.length; i++) {
      final musicPath = await cacheMusic('${bookId}_music_$i', musicUrls[i]);
      if (musicPath != null) {
        cachedPaths['music_$i'] = musicPath;
      }
    }
    
    // Cache backgrounds
    for (int i = 0; i < backgroundUrls.length; i++) {
      final bgPath = await cacheBackground('${bookId}_bg_$i', backgroundUrls[i]);
      if (bgPath != null) {
        cachedPaths['background_$i'] = bgPath;
      }
    }
    
    return cachedPaths;
  }
}