import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Production configuration for BookSphere client
class ProductionConfig {
  // Default server endpoints (can be overridden)
  static const String _defaultServerUrl = 'http://localhost:3000';
  static const String _defaultWebSocketUrl = 'ws://localhost:3000';
  
  // Environment-specific configurations
  static late String _serverUrl;
  static late String _webSocketUrl;
  static late bool _enableOfflineMode;
  static late int _cacheSizeMB;
  static late bool _enableAnalytics;
  static late String _apiVersion;
  
  /// Initialize configuration based on platform and environment
  static void initialize({
    String? serverUrl,
    String? webSocketUrl,
    bool enableOfflineMode = true,
    int cacheSizeMB = 500,
    bool enableAnalytics = false,
    String apiVersion = 'v1',
  }) {
    _serverUrl = serverUrl ?? _getDefaultServerUrl();
    _webSocketUrl = webSocketUrl ?? _getDefaultWebSocketUrl();
    _enableOfflineMode = enableOfflineMode;
    _cacheSizeMB = cacheSizeMB;
    _enableAnalytics = enableAnalytics;
    _apiVersion = apiVersion;
  }
  
  /// Get default server URL based on platform
  static String _getDefaultServerUrl() {
    if (kIsWeb) {
      // For web builds, use relative URLs or current host
      return '${Uri.base.scheme}://${Uri.base.host}:3000';
    } else if (Platform.isAndroid) {
      // For Android, use localhost or specific IP
      return 'http://10.0.2.2:3000'; // Android emulator localhost
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop, use localhost
      return 'http://localhost:3000';
    }
    return _defaultServerUrl;
  }
  
  /// Get default WebSocket URL based on platform
  static String _getDefaultWebSocketUrl() {
    if (kIsWeb) {
      // For web builds, use WebSocket protocol
      final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${Uri.base.host}:3000';
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:3000';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'ws://localhost:3000';
    }
    return _defaultWebSocketUrl;
  }
  
  // Getters for configuration values
  static String get serverUrl => _serverUrl;
  static String get webSocketUrl => _webSocketUrl;
  static bool get enableOfflineMode => _enableOfflineMode;
  static int get cacheSizeMB => _cacheSizeMB;
  static bool get enableAnalytics => _enableAnalytics;
  static String get apiVersion => _apiVersion;
  
  // API endpoints
  static String get baseApiUrl => '$_serverUrl/api/$_apiVersion';
  static String get authUrl => '$baseApiUrl/auth';
  static String get booksUrl => '$baseApiUrl/books';
  static String get musicUrl => '$baseApiUrl/music';
  static String get moodUrl => '$baseApiUrl/mood';
  static String get progressUrl => '$baseApiUrl/progress';
  static String get uploadUrl => '$baseApiUrl/upload';
  static String get healthUrl => '$baseApiUrl/health';
  
  // File upload limits
  static const int maxBookSizeMB = 50;
  static const int maxMusicSizeMB = 20;
  static const int maxImageSizeMB = 10;
  
  // Supported file types
  static const List<String> supportedBookTypes = ['pdf', 'epub', 'txt'];
  static const List<String> supportedMusicTypes = ['mp3', 'wav', 'ogg', 'm4a'];
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Cache configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration offlineCacheExpiry = Duration(days: 30);
  
  // Network timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration responseTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(minutes: 10);
  
  // WebSocket configuration
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const int maxReconnectAttempts = 10;
  static const Duration pingInterval = Duration(seconds: 30);
  
  // UI configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  static const int maxRecentBooks = 10;
  static const int maxSearchResults = 50;
  
  // Security configuration
  static const Duration tokenRefreshInterval = Duration(minutes: 10);
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // Performance configuration
  static const int imageCompressionQuality = 80;
  static const int thumbnailSize = 200;
  static const int maxConcurrentDownloads = 3;
  
  // Feature flags
  static bool get enableMoodDetection => true;
  static bool get enableAutoSync => _enableOfflineMode;
  static bool get enableBiometricAuth => !kIsWeb;
  static bool get enablePushNotifications => !kIsWeb;
  
  /// Load configuration from external source (file, preferences, etc.)
  static Future<void> loadFromPreferences() async {
    try {
      // This would typically load from SharedPreferences or a config file
      // For now, we use defaults
      initialize();
    } catch (e) {
      // Fall back to defaults if loading fails
      initialize();
    }
  }
  
  /// Save configuration to preferences
  static Future<void> saveToPreferences() async {
    try {
      // This would typically save to SharedPreferences or a config file
      // Implementation depends on your preference storage mechanism
    } catch (e) {
      // Handle save error
      print('Failed to save configuration: $e');
    }
  }
  
  /// Update server configuration at runtime
  static void updateServerConfig({
    String? serverUrl,
    String? webSocketUrl,
  }) {
    if (serverUrl != null) _serverUrl = serverUrl;
    if (webSocketUrl != null) _webSocketUrl = webSocketUrl;
  }
  
  /// Validate current configuration
  static bool validateConfiguration() {
    try {
      Uri.parse(_serverUrl);
      Uri.parse(_webSocketUrl);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get platform-specific configuration
  static Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': _getCurrentPlatform(),
      'serverUrl': _serverUrl,
      'webSocketUrl': _webSocketUrl,
      'offlineMode': _enableOfflineMode,
      'cacheSize': _cacheSizeMB,
      'analytics': _enableAnalytics,
      'version': _apiVersion,
    };
  }
  
  static String _getCurrentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }
  
  /// Development/Debug helpers
  static bool get isDebugMode => !kIsWeb && 
    (_serverUrl.contains('localhost') || _serverUrl.contains('127.0.0.1'));
  
  static void printConfiguration() {
    if (isDebugMode) {
      print('BookSphere Configuration:');
      print('  Platform: ${_getCurrentPlatform()}');
      print('  Server URL: $_serverUrl');
      print('  WebSocket URL: $_webSocketUrl');
      print('  Offline Mode: $_enableOfflineMode');
      print('  Cache Size: ${_cacheSizeMB}MB');
      print('  Analytics: $_enableAnalytics');
      print('  API Version: $_apiVersion');
    }
  }
}

/// Environment-specific configurations
class EnvironmentConfig {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  static String get currentEnvironment {
    // This could be set during build time or loaded from configuration
    return kIsWeb ? production : development;
  }
  
  static bool get isDevelopment => currentEnvironment == development;
  static bool get isStaging => currentEnvironment == staging;
  static bool get isProduction => currentEnvironment == production;
}