import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/user.dart';

class AuthApi {
  static const String baseUrl = 'http://localhost:5000/api';
  final Logger _logger = Logger();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? fullName,
    String? theme,
    bool? dynamicBg,
    int? musicVolume,
    double? moodSensitivity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          if (fullName != null) 'full_name': fullName,
          if (theme != null) 'theme': theme,
          if (dynamicBg != null) 'dynamic_bg': dynamicBg,
          if (musicVolume != null) 'music_volume': musicVolume,
          if (moodSensitivity != null) 'mood_sensitivity': moodSensitivity,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Token refresh failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
      rethrow;
    }
  }

  Future<User> getProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['data']);
      } else {
        throw Exception('Get profile failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Get profile error: $e');
      rethrow;
    }
  }

  Future<User> updateProfile(
    String accessToken,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['data']);
      } else {
        throw Exception('Update profile failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Update profile error: $e');
      rethrow;
    }
  }
}