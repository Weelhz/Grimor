import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  // Authentication tokens
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  // User credentials (optional - for remember me functionality)
  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<void> setUsername(String username) async {
    await _storage.write(key: 'username', value: username);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<void> setUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  // Clear all secure data
  Future<void> clear() async {
    await _storage.deleteAll();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}