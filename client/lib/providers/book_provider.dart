import 'package:flutter/foundation.dart';
import 'dart:io';
import '../api/book_api.dart';
import '../models/book.dart';
import '../models/preset.dart';
import '../services/file_service.dart';
import '../storage/local_store.dart';
import '../models/sync.dart';

class BookProvider with ChangeNotifier {
  final BookApi _bookApi = BookApi();
  final FileService _fileService = FileService.instance;
  final LocalStore _localStore = LocalStore();
  
  // Book state
  List<Book> _books = [];
  List<Preset> _presets = [];
  Book? _currentBook;
  Preset? _currentPreset;
  bool _isLoading = false;
  String? _error;
  
  // Reading state
  int _currentChapter = 1;
  double _currentPageFraction = 0.0;
  double _readingProgress = 0.0;
  
  // Getters
  List<Book> get books => _books;
  List<Preset> get presets => _presets;
  Book? get currentBook => _currentBook;
  Preset? get currentPreset => _currentPreset;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentChapter => _currentChapter;
  double get currentPageFraction => _currentPageFraction;
  double get readingProgress => _readingProgress;
  
  // Initialize book provider
  Future<void> initialize() async {
    // Implementation would initialize the provider
  }
  
  // Load books from API
  Future<void> loadBooks({String? accessToken, String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _books = await _bookApi.getBooks(
        accessToken: accessToken,
        searchQuery: searchQuery,
      );
      
      // Cache books locally
      for (final book in _books) {
        await _localStore.saveBook(book);
      }
    } catch (e) {
      _error = 'Error loading books: $e';
      
      // Load from local storage as fallback
      try {
        _books = await _localStore.getAllBooks();
      } catch (localError) {
        _error = 'Error loading books: $localError';
        _books = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Upload book with token and file
  Future<bool> uploadBook(String accessToken, File bookFile, String title) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final book = await _bookApi.uploadBook(accessToken, bookFile, title);
      _books.add(book);
      
      // Cache book locally
      await _localStore.saveBook(book);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error uploading book: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Set current book
  void setCurrentBook(Book book) {
    _currentBook = book;
    _currentChapter = 1;
    _currentPageFraction = 0.0;
    _readingProgress = 0.0;
    notifyListeners();
  }
  
  // Clear current book
  void clearCurrentBook() {
    _currentBook = null;
    _currentChapter = 1;
    _currentPageFraction = 0.0;
    _readingProgress = 0.0;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}