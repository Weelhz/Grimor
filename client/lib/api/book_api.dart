import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/book.dart';

class BookApi {
  static const String baseUrl = 'http://localhost:5000/api';
  final Logger _logger = Logger();

  Future<List<Book>> getBooks({
    String? accessToken,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/books').replace(queryParameters: {
        if (searchQuery != null) 'q': searchQuery,
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final books = data['data']['books'] as List;
        return books.map((book) => Book.fromJson(book)).toList();
      } else {
        throw Exception('Get books failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Get books error: $e');
      rethrow;
    }
  }

  Future<Book> getBook(int bookId, {String? accessToken}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/books/$bookId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Book.fromJson(data['data']);
      } else {
        throw Exception('Get book failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Get book error: $e');
      rethrow;
    }
  }

  Future<Book> uploadBook(
    String accessToken,
    File bookFile,
    String title,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/books/upload'),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['title'] = title;
      request.files.add(await http.MultipartFile.fromPath('book', bookFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        return Book.fromJson(data['data']);
      } else {
        throw Exception('Upload book failed: $responseBody');
      }
    } catch (e) {
      _logger.e('Upload book error: $e');
      rethrow;
    }
  }

  Future<Book> updateBook(
    String accessToken,
    int bookId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/books/$bookId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Book.fromJson(data['data']);
      } else {
        throw Exception('Update book failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Update book error: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String accessToken, int bookId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/books/$bookId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Delete book failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Delete book error: $e');
      rethrow;
    }
  }
}