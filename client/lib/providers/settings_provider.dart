import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../storage/local_store.dart';

class SettingsProvider extends ChangeNotifier {
  final LocalStore _localStore = LocalStore();
  final Logger _logger = Logger();

  SettingsProvider();

  // Theme settings
  bool get isDarkMode => _localStore.isDarkMode;
  set isDarkMode(bool value) {
    _localStore.isDarkMode = value;
    _logger.d('Theme changed to: ${value ? 'dark' : 'light'}');
    notifyListeners();
  }

  // Background settings
  bool get dynamicBackground => _localStore.dynamicBackground;
  set dynamicBackground(bool value) {
    _localStore.dynamicBackground = value;
    _logger.d('Dynamic background: $value');
    notifyListeners();
  }

  // Music settings
  int get musicVolume => _localStore.musicVolume;
  set musicVolume(int value) {
    _localStore.musicVolume = value.clamp(0, 100);
    _logger.d('Music volume: $value');
    notifyListeners();
  }

  // Mood settings
  double get moodSensitivity => _localStore.moodSensitivity;
  set moodSensitivity(double value) {
    _localStore.moodSensitivity = value.clamp(0.1, 2.0);
    _logger.d('Mood sensitivity: $value');
    notifyListeners();
  }

  // Offline settings
  bool get isOfflineMode => _localStore.isOfflineMode;
  set isOfflineMode(bool value) {
    _localStore.isOfflineMode = value;
    _logger.d('Offline mode: $value');
    notifyListeners();
  }

  // Reading progress
  Map<String, dynamic> getReadingProgress(int bookId) {
    return _localStore.getReadingProgress(bookId);
  }

  void setReadingProgress(int bookId, int chapter, double pageFraction) {
    _localStore.setReadingProgress(bookId, chapter, pageFraction);
    _logger.d('Reading progress saved: book=$bookId, chapter=$chapter, page=$pageFraction');
  }

  // Cache management
  List<String> get cachedBooks => _localStore.cachedBooks;
  
  void addCachedBook(String bookId) {
    _localStore.addCachedBook(bookId);
    _logger.d('Book added to cache: $bookId');
    notifyListeners();
  }

  void removeCachedBook(String bookId) {
    _localStore.removeCachedBook(bookId);
    _logger.d('Book removed from cache: $bookId');
    notifyListeners();
  }

  // Sync settings
  int get lastSyncTimestamp => _localStore.lastSyncTimestamp;
  set lastSyncTimestamp(int value) {
    _localStore.lastSyncTimestamp = value;
    _logger.d('Last sync timestamp updated: $value');
  }

  // Bulk settings update
  void updateSettings(Map<String, dynamic> settings) {
    bool hasChanges = false;

    if (settings.containsKey('isDarkMode') && settings['isDarkMode'] != isDarkMode) {
      isDarkMode = settings['isDarkMode'];
      hasChanges = true;
    }

    if (settings.containsKey('dynamicBackground') && settings['dynamicBackground'] != dynamicBackground) {
      dynamicBackground = settings['dynamicBackground'];
      hasChanges = true;
    }

    if (settings.containsKey('musicVolume') && settings['musicVolume'] != musicVolume) {
      musicVolume = settings['musicVolume'];
      hasChanges = true;
    }

    if (settings.containsKey('moodSensitivity') && settings['moodSensitivity'] != moodSensitivity) {
      moodSensitivity = settings['moodSensitivity'];
      hasChanges = true;
    }

    if (settings.containsKey('isOfflineMode') && settings['isOfflineMode'] != isOfflineMode) {
      isOfflineMode = settings['isOfflineMode'];
      hasChanges = true;
    }

    if (hasChanges) {
      _logger.i('Settings updated');
      notifyListeners();
    }
  }

  Future<void> clearAllSettings() async {
    await _localStore.clear();
    _logger.i('All settings cleared');
    notifyListeners();
  }
}