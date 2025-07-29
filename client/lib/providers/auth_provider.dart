import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../api/auth_api.dart';
import '../models/user.dart';
import '../storage/secure_store.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  final SecureStore _secureStore = SecureStore();
  final Logger _logger = Logger();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final isLoggedIn = await _secureStore.isLoggedIn();
    if (isLoggedIn) {
      await _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final accessToken = await _secureStore.getAccessToken();
      if (accessToken != null) {
        _user = await _authApi.getProfile(accessToken);
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to load user profile: $e');
      // Token might be expired, try to refresh
      await _tryRefreshToken();
    }
  }

  Future<void> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStore.getRefreshToken();
      if (refreshToken != null) {
        final tokens = await _authApi.refreshToken(refreshToken);
        await _secureStore.setAccessToken(tokens['accessToken']);
        await _secureStore.setRefreshToken(tokens['refreshToken']);
        await _loadUserProfile();
      }
    } catch (e) {
      _logger.e('Failed to refresh token: $e');
      await logout();
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final authData = await _authApi.login(username, password);
      
      _user = User.fromJson(authData['user']);
      await _secureStore.setAccessToken(authData['accessToken']);
      await _secureStore.setRefreshToken(authData['refreshToken']);
      await _secureStore.setUsername(username);
      await _secureStore.setUserId(_user!.id.toString());

      _logger.i('User logged in successfully: ${_user!.username}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _logger.e('Login failed: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    String? fullName,
    String? theme,
    bool? dynamicBg,
    int? musicVolume,
    double? moodSensitivity,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final authData = await _authApi.register(
        username: username,
        password: password,
        fullName: fullName,
        theme: theme,
        dynamicBg: dynamicBg,
        musicVolume: musicVolume,
        moodSensitivity: moodSensitivity,
      );

      _user = User.fromJson(authData['user']);
      await _secureStore.setAccessToken(authData['accessToken']);
      await _secureStore.setRefreshToken(authData['refreshToken']);
      await _secureStore.setUsername(username);
      await _secureStore.setUserId(_user!.id.toString());

      _logger.i('User registered successfully: ${_user!.username}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _logger.e('Registration failed: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    await _secureStore.clear();
    _logger.i('User logged out');
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final accessToken = await _secureStore.getAccessToken();
      if (accessToken != null) {
        _user = await _authApi.updateProfile(accessToken, updates);
        _logger.i('Profile updated successfully');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _logger.e('Profile update failed: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStore.getAccessToken();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}