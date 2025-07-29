import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../api/book_api.dart';
import '../models/book.dart';
import '../models/preset.dart';
import '../services/file_service.dart';
import '../storage/local_store.dart';

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
  String _errorMessage = '';
  
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
  String get errorMessage => _errorMessage;
  int get currentChapter => _currentChapter;
  double get currentPageFraction => _currentPageFraction;
  double get readingProgress => _readingProgress;
  
  // Initialize book provider
  Future<void> initialize() async {
    await loadBooks();
    await loadPresets();
  }
  
  // Load books from API
  Future<void> loadBooks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _books = await _bookApi.getAllBooks();
      
      // Cache books locally
      for (final book in _books) {
        await _localStore.saveBook(book);
      }
    } catch (e) {
      _errorMessage = 'Error loading books: $e';
      
      // Load from local storage as fallback
      try {
        _books = await _localStore.getAllBooks();
      } catch (localError) {
        _errorMessage = 'Error loading books: $localError';
        _books = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load presets from API
  Future<void> loadPresets() async {
    try {
      _presets = await _bookApi.getAllPresets();
    } catch (e) {
      print('Error loading presets: $e');
      _presets = [];
    }
    notifyListeners();
  }
  
  // Upload book
  Future<void> uploadBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'txt'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          _isLoading = true;
          notifyListeners();
          
          final book = await _bookApi.uploadBook(
            file: File(file.path!),
            title: file.name,
          );
          
          _books.add(book);
          
          // Cache book locally
          await _localStore.saveBook(book);
          
          // Save book file locally
          await _fileService.saveBookFile(File(file.path!), book.id.toString());
          
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Error uploading book: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Select book for reading
  Future<void> selectBook(Book book) async {
    _currentBook = book;
    
    // Load reading progress
    final progress = await _localStore.getLatestReadingProgress(book.id);
    if (progress != null) {
      _currentChapter = progress.chapter;
      _currentPageFraction = progress.pageFraction;
      _readingProgress = (_currentChapter - 1 + _currentPageFraction) / _getTotalChapters();
    } else {
      _currentChapter = 1;
      _currentPageFraction = 0.0;
      _readingProgress = 0.0;
    }
    
    notifyListeners();
  }
  
  // Update reading progress
  Future<void> updateReadingProgress(int chapter, double pageFraction) async {
    if (_currentBook == null) return;
    
    _currentChapter = chapter;
    _currentPageFraction = pageFraction;
    _readingProgress = (_currentChapter - 1 + _currentPageFraction) / _getTotalChapters();
    
    // Save progress locally
    final progress = ReadingProgress(
      bookId: _currentBook!.id,
      presetId: _currentPreset?.id,
      chapter: chapter,
      pageFraction: pageFraction,
      timestamp: DateTime.now(),
    );
    
    await _localStore.saveReadingProgress(progress);
    
    notifyListeners();
  }
  
  // Get total chapters (placeholder - would be determined by book content)
  int _getTotalChapters() {
    // This would typically be determined by analyzing the book content
    return 20; // Placeholder
  }
  
  // Create preset
  Future<void> createPreset(String presetName, int bookId) async {
    try {
      final preset = await _bookApi.createPreset(presetName, bookId);
      _presets.add(preset);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error creating preset: $e';
      notifyListeners();
    }
  }
  
  // Select preset
  void selectPreset(Preset preset) {
    _currentPreset = preset;
    notifyListeners();
  }
  
  // Update preset
  Future<void> updatePreset(int presetId, String newName) async {
    try {
      final updatedPreset = await _bookApi.updatePreset(presetId, newName);
      final index = _presets.indexWhere((p) => p.id == presetId);
      if (index != -1) {
        _presets[index] = updatedPreset;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error updating preset: $e';
      notifyListeners();
    }
  }
  
  // Delete preset
  Future<void> deletePreset(int presetId) async {
    try {
      await _bookApi.deletePreset(presetId);
      _presets.removeWhere((p) => p.id == presetId);
      
      // Clear current preset if it was deleted
      if (_currentPreset?.id == presetId) {
        _currentPreset = null;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error deleting preset: $e';
      notifyListeners();
    }
  }
  
  // Delete book
  Future<void> deleteBook(int bookId) async {
    try {
      await _bookApi.deleteBook(bookId);
      _books.removeWhere((b) => b.id == bookId);
      
      // Clear current book if it was deleted
      if (_currentBook?.id == bookId) {
        _currentBook = null;
        _currentChapter = 1;
        _currentPageFraction = 0.0;
        _readingProgress = 0.0;
      }
      
      // Delete from local storage
      await _localStore.deleteBook(bookId.toString());
      await _fileService.deleteBookFile(bookId.toString());
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error deleting book: $e';
      notifyListeners();
    }
  }
  
  // Search books
  Future<List<Book>> searchBooks(String query) async {
    try {
      return await _bookApi.searchBooks(query);
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }
  
  // Get book file for reading
  Future<File?> getBookFile(int bookId) async {
    // Try to get from local storage first
    final localFile = await _fileService.getBookFile(bookId.toString());
    if (localFile != null) {
      return localFile;
    }
    
    // If not found locally, get signed URL from server
    try {
      final signedUrl = await _bookApi.getBookSignedUrl(bookId);
      // Download and cache the file
      final cachedFile = await _fileService.downloadAndCacheAsset(
        signedUrl, 
        'book_$bookId',
      );
      return cachedFile;
    } catch (e) {
      print('Error getting book file: $e');
      return null;
    }
  }
  
  // Get book content for specific chapter
  Future<String> getBookContent(int bookId, int chapter) async {
    final bookFile = await getBookFile(bookId);
    if (bookFile == null) {
      throw Exception('Book file not found');
    }
    
    // This would typically involve parsing the book file
    // For now, return placeholder content
    return 'Chapter $chapter content...';
  }
  
  // Get book metadata
  Future<Map<String, dynamic>> getBookMetadata(int bookId) async {
    final book = _books.firstWhere((b) => b.id == bookId);
    final bookFile = await getBookFile(bookId);
    
    if (bookFile == null) {
      throw Exception('Book file not found');
    }
    
    // This would typically involve parsing the book file for metadata
    return {
      'title': book.title,
      'file_path': book.filepath,
      'chapters': _getTotalChapters(),
      'file_size': await bookFile.length(),
      'format': book.filepath.split('.').last,
    };
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  // Get presets for current book
  List<Preset> getPresetsForBook(int bookId) {
    return _presets.where((preset) => preset.bookId == bookId).toList();
  }
  
  // Get reading statistics
  Map<String, dynamic> getReadingStats() {
    final totalBooks = _books.length;
    final booksRead = _books.where((book) => 
      _books.any((b) => b.id == book.id && _readingProgress > 0)
    ).length;
    
    return {
      'total_books': totalBooks,
      'books_read': booksRead,
      'current_progress': _readingProgress,
      'current_chapter': _currentChapter,
      'total_chapters': _getTotalChapters(),
    };
  }
  
  // Import book from file
  Future<void> importBookFromFile(File file, String title) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final book = await _bookApi.uploadBook(file: file, title: title);
      _books.add(book);
      
      // Cache book locally
      await _localStore.saveBook(book);
      await _fileService.saveBookFile(file, book.id.toString());
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error importing book: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}