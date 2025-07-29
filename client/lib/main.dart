import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/music_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'services/socket_service.dart';
import 'services/cache_service.dart';
import 'services/file_service.dart';
import 'services/platform_service.dart';
import 'storage/local_store.dart';
import 'storage/secure_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final fileService = FileService.instance;
  final platformService = PlatformService.instance;
  final cacheService = CacheService();
  final socketService = SocketService();
  
  // Initialize services
  await fileService.initialize();
  await platformService.optimizeForPlatform();
  await cacheService.initialize();
  
  print('Book Sphere client initialized');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: BookSphereApp(),
    ),
  );
}