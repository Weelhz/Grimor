import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PlatformService {
  static PlatformService? _instance;
  static PlatformService get instance => _instance ??= PlatformService._();
  PlatformService._();

  // Platform detection
  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;
  bool get isWindows => Platform.isWindows;
  bool get isMacOS => Platform.isMacOS;
  bool get isLinux => Platform.isLinux;
  bool get isWeb => kIsWeb;
  bool get isMobile => isAndroid || isIOS;
  bool get isDesktop => isWindows || isMacOS || isLinux;

  // Platform-specific configurations
  Map<String, dynamic> get platformConfig {
    if (isAndroid) {
      return {
        'name': 'Android',
        'file_picker': true,
        'notifications': true,
        'background_sync': true,
        'audio_session': true,
        'media_store': true,
        'scoped_storage': true,
      };
    } else if (isIOS) {
      return {
        'name': 'iOS',
        'file_picker': true,
        'notifications': true,
        'background_sync': true,
        'audio_session': true,
        'media_store': false,
        'scoped_storage': false,
      };
    } else if (isWindows) {
      return {
        'name': 'Windows',
        'file_picker': true,
        'notifications': true,
        'background_sync': true,
        'audio_session': true,
        'media_store': false,
        'scoped_storage': false,
      };
    } else if (isWeb) {
      return {
        'name': 'Web',
        'file_picker': true,
        'notifications': false,
        'background_sync': false,
        'audio_session': false,
        'media_store': false,
        'scoped_storage': false,
      };
    } else {
      return {
        'name': 'Unknown',
        'file_picker': false,
        'notifications': false,
        'background_sync': false,
        'audio_session': false,
        'media_store': false,
        'scoped_storage': false,
      };
    }
  }

  // Get device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'api_level': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'brand': androidInfo.brand,
          'hardware': androidInfo.hardware,
          'supported_abis': androidInfo.supportedAbis,
        };
      } else if (isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_name': iosInfo.systemName,
          'machine': iosInfo.utsname.machine,
          'is_simulator': iosInfo.isPhysicalDevice == false,
        };
      } else if (isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return {
          'platform': 'Windows',
          'version': windowsInfo.displayVersion,
          'build': windowsInfo.buildNumber,
          'computer_name': windowsInfo.computerName,
          'user_name': windowsInfo.userName,
          'major_version': windowsInfo.majorVersion,
          'minor_version': windowsInfo.minorVersion,
        };
      } else if (isWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return {
          'platform': 'Web',
          'browser': webInfo.browserName.name,
          'version': webInfo.appVersion,
          'user_agent': webInfo.userAgent,
          'vendor': webInfo.vendor,
          'platform_type': webInfo.platform,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    
    return {
      'platform': 'Unknown',
      'error': 'Unable to get device information',
    };
  }

  // Permission handling
  Future<bool> requestStoragePermission() async {
    if (isWeb) return true; // Web handles permissions differently
    
    if (isAndroid) {
      // Check Android version for scoped storage
      final deviceInfo = await getDeviceInfo();
      final apiLevel = deviceInfo['api_level'] as int? ?? 0;
      
      if (apiLevel >= 30) {
        // Android 11+ uses scoped storage
        return true; // No explicit permission needed for scoped storage
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (isIOS) {
      // iOS handles file access through document picker
      return true;
    } else if (isDesktop) {
      // Desktop platforms don't need storage permissions
      return true;
    }
    
    return false;
  }

  Future<bool> requestNotificationPermission() async {
    if (isWeb || isDesktop) return true; // Handle differently on web/desktop
    
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    if (isWeb) return true; // Web handles this in browser
    
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'storage': await requestStoragePermission(),
      'notification': await requestNotificationPermission(),
      'microphone': await requestMicrophonePermission(),
    };
  }

  // File system paths
  Future<String> getAppDocumentsDirectory() async {
    if (isWeb) {
      return '/app_documents'; // Web uses IndexedDB
    }
    
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<String> getAppCacheDirectory() async {
    if (isWeb) {
      return '/app_cache'; // Web uses IndexedDB
    }
    
    final dir = await getApplicationCacheDirectory();
    return dir.path;
  }

  Future<String> getAppTempDirectory() async {
    if (isWeb) {
      return '/app_temp'; // Web uses IndexedDB
    }
    
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  Future<String?> getDownloadsDirectory() async {
    if (isWeb) return null; // Web handles downloads differently
    
    if (isAndroid || isIOS) {
      return null; // Use platform-specific download handling
    }
    
    if (isDesktop) {
      try {
        final dir = await getDownloadsDirectory();
        return dir?.path;
      } catch (e) {
        print('Error getting downloads directory: $e');
        return null;
      }
    }
    
    return null;
  }

  // Platform-specific features
  Future<void> setSystemUIOverlayStyle() async {
    if (isMobile) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) async {
    if (isMobile) {
      await SystemChrome.setPreferredOrientations(orientations);
    }
  }

  Future<void> enableFullScreen() async {
    if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  Future<void> disableFullScreen() async {
    if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // Audio session management
  Future<void> configureAudioSession() async {
    if (isMobile) {
      // Platform-specific audio session configuration
      if (isAndroid) {
        // Android audio focus management
        await _configureAndroidAudioSession();
      } else if (isIOS) {
        // iOS audio session configuration
        await _configureIOSAudioSession();
      }
    }
  }

  Future<void> _configureAndroidAudioSession() async {
    // Android-specific audio configuration
    try {
      // This would typically use a platform channel or plugin
      // For now, we'll use a placeholder
      print('Configuring Android audio session');
    } catch (e) {
      print('Error configuring Android audio session: $e');
    }
  }

  Future<void> _configureIOSAudioSession() async {
    // iOS-specific audio configuration
    try {
      // This would typically use a platform channel or plugin
      // For now, we'll use a placeholder
      print('Configuring iOS audio session');
    } catch (e) {
      print('Error configuring iOS audio session: $e');
    }
  }

  // Background app handling
  Future<void> enableBackgroundProcessing() async {
    if (isMobile) {
      // Enable background app refresh and processing
      try {
        // Platform-specific background processing setup
        if (isAndroid) {
          await _setupAndroidBackgroundProcessing();
        } else if (isIOS) {
          await _setupIOSBackgroundProcessing();
        }
      } catch (e) {
        print('Error enabling background processing: $e');
      }
    }
  }

  Future<void> _setupAndroidBackgroundProcessing() async {
    // Android background processing setup
    print('Setting up Android background processing');
  }

  Future<void> _setupIOSBackgroundProcessing() async {
    // iOS background processing setup
    print('Setting up iOS background processing');
  }

  // Network connectivity
  Future<bool> isNetworkConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Platform-specific UI adjustments
  double getStatusBarHeight() {
    if (isMobile) {
      return MediaQuery.of(navigatorKey.currentContext!).padding.top;
    }
    return 0;
  }

  double getBottomPadding() {
    if (isMobile) {
      return MediaQuery.of(navigatorKey.currentContext!).padding.bottom;
    }
    return 0;
  }

  // App lifecycle management
  Future<void> setupAppLifecycleObserver() async {
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
  }

  // Platform-specific optimizations
  Future<void> optimizeForPlatform() async {
    if (isAndroid) {
      await _optimizeForAndroid();
    } else if (isIOS) {
      await _optimizeForIOS();
    } else if (isWindows) {
      await _optimizeForWindows();
    } else if (isWeb) {
      await _optimizeForWeb();
    }
  }

  Future<void> _optimizeForAndroid() async {
    // Android-specific optimizations
    await setSystemUIOverlayStyle();
    await configureAudioSession();
    await enableBackgroundProcessing();
  }

  Future<void> _optimizeForIOS() async {
    // iOS-specific optimizations
    await setSystemUIOverlayStyle();
    await configureAudioSession();
    await enableBackgroundProcessing();
  }

  Future<void> _optimizeForWindows() async {
    // Windows-specific optimizations
    print('Optimizing for Windows');
  }

  Future<void> _optimizeForWeb() async {
    // Web-specific optimizations
    print('Optimizing for Web');
  }

  // Error handling
  Future<void> handlePlatformError(dynamic error) async {
    print('Platform error: $error');
    
    if (error is PlatformException) {
      switch (error.code) {
        case 'PERMISSION_DENIED':
          print('Permission denied: ${error.message}');
          break;
        case 'UNAVAILABLE':
          print('Feature unavailable: ${error.message}');
          break;
        default:
          print('Unknown platform error: ${error.code} - ${error.message}');
      }
    }
  }
}

// App lifecycle observer
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed');
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App paused');
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        print('App detached');
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        _onAppHidden();
        break;
    }
  }

  void _onAppResumed() {
    // Handle app resume
    // Resume audio playback, sync data, etc.
  }

  void _onAppPaused() {
    // Handle app pause
    // Pause audio playback, save state, etc.
  }

  void _onAppInactive() {
    // Handle app inactive
  }

  void _onAppDetached() {
    // Handle app detached
  }

  void _onAppHidden() {
    // Handle app hidden
  }
}

// Global navigator key for context access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Platform-specific constants
class PlatformConstants {
  static const androidMinSdkVersion = 21;
  static const iosMinVersion = '12.0';
  static const windowsMinVersion = '10.0.17763.0';
  
  static const supportedAudioFormats = {
    'android': ['mp3', 'aac', 'ogg', 'wav', 'flac'],
    'ios': ['mp3', 'aac', 'wav', 'm4a', 'caf'],
    'windows': ['mp3', 'wav', 'wma', 'flac'],
    'web': ['mp3', 'wav', 'ogg', 'aac'],
  };
  
  static const maxFileSizes = {
    'android': 100 * 1024 * 1024, // 100MB
    'ios': 100 * 1024 * 1024, // 100MB
    'windows': 500 * 1024 * 1024, // 500MB
    'web': 50 * 1024 * 1024, // 50MB
  };
}

// Platform feature detection
class PlatformFeatures {
  static bool get supportsBackgroundAudio => 
      PlatformService.instance.isMobile || PlatformService.instance.isDesktop;
  
  static bool get supportsFileSystemAccess => 
      !PlatformService.instance.isWeb;
  
  static bool get supportsNotifications => 
      PlatformService.instance.isMobile;
  
  static bool get supportsPushNotifications => 
      PlatformService.instance.isMobile;
  
  static bool get supportsAppShortcuts => 
      PlatformService.instance.isMobile;
  
  static bool get supportsWidgets => 
      PlatformService.instance.isMobile;
  
  static bool get supportsBackgroundSync => 
      PlatformService.instance.isMobile || PlatformService.instance.isDesktop;
}