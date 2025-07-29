import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import '../models/mood.dart';

class SocketService {
  static const String serverUrl = 'http://localhost:5000';
  IO.Socket? _socket;
  final Logger _logger = Logger();
  
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect(String accessToken) async {
    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'auth': {'token': accessToken},
      });

      _socket!.on('connect', (_) {
        _logger.i('Connected to WebSocket server');
      });

      _socket!.on('disconnect', (_) {
        _logger.i('Disconnected from WebSocket server');
      });

      _socket!.on('connect_error', (error) {
        _logger.e('WebSocket connection error: $error');
      });

      _socket!.on('error', (error) {
        _logger.e('WebSocket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      _logger.e('Socket connection error: $e');
      rethrow;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // Room management
  void joinBookRoom(int bookId, int presetId) {
    _socket?.emit('room:join', {
      'bookId': bookId,
      'presetId': presetId,
    });
  }

  void leaveBookRoom(int bookId) {
    _socket?.emit('room:leave', {'bookId': bookId});
  }

  // Progress updates
  void sendProgressUpdate(int bookId, int presetId, int chapter, double pageFraction) {
    _socket?.emit('progress:update', {
      'bookId': bookId,
      'presetId': presetId,
      'chapter': chapter,
      'pageFraction': pageFraction,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Settings updates
  void updateSettings(Map<String, dynamic> settings) {
    _socket?.emit('settings:update', settings);
  }

  // Event listeners
  void onMoodTrigger(Function(MoodTrigger) callback) {
    _socket?.on('mood:trigger', (data) {
      final moodTrigger = MoodTrigger.fromJson(data);
      callback(moodTrigger);
    });
  }

  void onSyncStatus(Function(Map<String, dynamic>) callback) {
    _socket?.on('sync:status', (data) {
      callback(data);
    });
  }

  void onUserJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('user:joined', (data) {
      callback(data);
    });
  }

  void onUserLeft(Function(Map<String, dynamic>) callback) {
    _socket?.on('user:left', (data) {
      callback(data);
    });
  }

  void onError(Function(Map<String, dynamic>) callback) {
    _socket?.on('error', (data) {
      callback(data);
    });
  }

  // Ping/Pong for connection monitoring
  void ping() {
    _socket?.emit('ping');
  }

  void onPong(Function() callback) {
    _socket?.on('pong', (_) {
      callback();
    });
  }

  // Remove listeners
  void removeAllListeners() {
    _socket?.clearListeners();
  }
}