import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

class FileUtils {
  // Supported file types
  static const List<String> supportedBookFormats = ['.pdf', '.epub', '.txt'];
  static const List<String> supportedMusicFormats = ['.mp3', '.wav', '.m4a', '.ogg'];
  static const List<String> supportedImageFormats = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  
  // File size limits (in bytes)
  static const int maxBookSize = 50 * 1024 * 1024; // 50MB
  static const int maxMusicSize = 20 * 1024 * 1024; // 20MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  
  // Validate file type
  static bool isValidBookFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedBookFormats.contains(extension);
  }
  
  static bool isValidMusicFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedMusicFormats.contains(extension);
  }
  
  static bool isValidImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedImageFormats.contains(extension);
  }
  
  // Validate file size
  static bool isValidFileSize(File file, String fileType) {
    final size = file.lengthSync();
    
    switch (fileType.toLowerCase()) {
      case 'book':
        return size <= maxBookSize;
      case 'music':
        return size <= maxMusicSize;
      case 'image':
        return size <= maxImageSize;
      default:
        return false;
    }
  }
  
  // Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
  
  // Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }
  
  // Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  // Get file name with extension
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
  
  // Generate file hash
  static Future<String> generateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Create directory if it doesn't exist
  static Future<Directory> ensureDirectoryExists(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
  
  // Copy file to destination
  static Future<File> copyFile(File source, String destinationPath) async {
    await ensureDirectoryExists(path.dirname(destinationPath));
    return await source.copy(destinationPath);
  }
  
  // Move file to destination
  static Future<File> moveFile(File source, String destinationPath) async {
    await ensureDirectoryExists(path.dirname(destinationPath));
    return await source.rename(destinationPath);
  }
  
  // Delete file safely
  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  // Read file as string
  static Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }
  
  // Write string to file
  static Future<void> writeStringToFile(String content, String filePath) async {
    await ensureDirectoryExists(path.dirname(filePath));
    final file = File(filePath);
    await file.writeAsString(content);
  }
  
  // Read file as bytes
  static Future<Uint8List> readFileAsBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }
  
  // Write bytes to file
  static Future<void> writeBytesToFile(Uint8List bytes, String filePath) async {
    await ensureDirectoryExists(path.dirname(filePath));
    final file = File(filePath);
    await file.writeAsBytes(bytes);
  }
  
  // Get file metadata
  static Future<FileMetadata> getFileMetadata(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    
    return FileMetadata(
      path: filePath,
      name: getFileName(filePath),
      extension: getFileExtension(filePath),
      size: stat.size,
      sizeString: getFileSizeString(stat.size),
      created: stat.changed,
      modified: stat.modified,
      isDirectory: stat.type == FileSystemEntityType.directory,
      exists: await file.exists(),
    );
  }
  
  // List files in directory
  static Future<List<FileMetadata>> listFilesInDirectory(
    String directoryPath, {
    bool recursive = false,
    List<String>? extensions,
  }) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];
    
    final files = <FileMetadata>[];
    
    await for (final entity in dir.list(recursive: recursive)) {
      if (entity is File) {
        final metadata = await getFileMetadata(entity.path);
        
        if (extensions == null || extensions.contains(metadata.extension)) {
          files.add(metadata);
        }
      }
    }
    
    return files;
  }
  
  // Clean up temporary files
  static Future<void> cleanupTempFiles(String tempDirectory) async {
    final dir = Directory(tempDirectory);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (e) {
            // Ignore errors during cleanup
          }
        }
      }
    }
  }
  
  // Validate file permissions
  static Future<bool> canReadFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.openRead().first;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> canWriteFile(String filePath) async {
    try {
      final file = File(filePath);
      final randomAccess = await file.open(mode: FileMode.write);
      await randomAccess.close();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Create backup of file
  static Future<File> createBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${filePath}.backup.$timestamp';
    
    return await copyFile(file, backupPath);
  }
  
  // Restore file from backup
  static Future<File> restoreFromBackup(String originalPath, String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw FileSystemException('Backup file does not exist', backupPath);
    }
    
    return await copyFile(backupFile, originalPath);
  }
  
  // Get directory size
  static Future<int> getDirectorySize(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return 0;
    
    int totalSize = 0;
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }
    
    return totalSize;
  }
  
  // Compress file (simple gzip)
  static Future<File> compressFile(File sourceFile, String outputPath) async {
    final bytes = await sourceFile.readAsBytes();
    final compressed = gzip.encode(bytes);
    
    await ensureDirectoryExists(path.dirname(outputPath));
    final compressedFile = File(outputPath);
    await compressedFile.writeAsBytes(compressed);
    
    return compressedFile;
  }
  
  // Decompress file (simple gzip)
  static Future<File> decompressFile(File compressedFile, String outputPath) async {
    final compressedBytes = await compressedFile.readAsBytes();
    final decompressed = gzip.decode(compressedBytes);
    
    await ensureDirectoryExists(path.dirname(outputPath));
    final decompressedFile = File(outputPath);
    await decompressedFile.writeAsBytes(decompressed);
    
    return decompressedFile;
  }
  
  // Generate unique filename
  static String generateUniqueFilename(String basePath, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
    return path.join(basePath, 'file_${timestamp}_$random$extension');
  }
  
  // Sanitize filename
  static String sanitizeFilename(String filename) {
    // Remove or replace invalid characters
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
  
  // Get MIME type from file extension
  static String getMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.epub':
        return 'application/epub+zip';
      case '.txt':
        return 'text/plain';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.ogg':
        return 'audio/ogg';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

class FileMetadata {
  final String path;
  final String name;
  final String extension;
  final int size;
  final String sizeString;
  final DateTime created;
  final DateTime modified;
  final bool isDirectory;
  final bool exists;

  FileMetadata({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.sizeString,
    required this.created,
    required this.modified,
    required this.isDirectory,
    required this.exists,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'extension': extension,
      'size': size,
      'size_string': sizeString,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
      'is_directory': isDirectory,
      'exists': exists,
    };
  }
}

// File validation utilities
class FileValidator {
  static Future<FileValidationResult> validateFile(
    File file,
    String expectedType,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Check if file exists
    if (!await file.exists()) {
      errors.add('File does not exist');
      return FileValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }
    
    // Check file size
    if (!FileUtils.isValidFileSize(file, expectedType)) {
      errors.add('File size exceeds maximum allowed size');
    }
    
    // Check file type
    final isValidType = switch (expectedType.toLowerCase()) {
      'book' => FileUtils.isValidBookFile(file.path),
      'music' => FileUtils.isValidMusicFile(file.path),
      'image' => FileUtils.isValidImageFile(file.path),
      _ => false,
    };
    
    if (!isValidType) {
      errors.add('Invalid file type for $expectedType');
    }
    
    // Check read permissions
    if (!await FileUtils.canReadFile(file.path)) {
      errors.add('Cannot read file (permission denied)');
    }
    
    // File-specific validations
    if (expectedType.toLowerCase() == 'book') {
      final bookValidation = await _validateBookFile(file);
      errors.addAll(bookValidation.errors);
      warnings.addAll(bookValidation.warnings);
    }
    
    return FileValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  static Future<FileValidationResult> _validateBookFile(File file) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    try {
      final extension = FileUtils.getFileExtension(file.path);
      final size = await file.length();
      
      // Check if file is too small (likely empty or corrupted)
      if (size < 1024) {
        warnings.add('File is very small and may be empty or corrupted');
      }
      
      // Basic content validation based on file type
      if (extension == '.pdf') {
        final bytes = await file.readAsBytes();
        final header = String.fromCharCodes(bytes.take(8));
        if (!header.startsWith('%PDF-')) {
          errors.add('Invalid PDF file format');
        }
      } else if (extension == '.epub') {
        // EPUB files are ZIP archives
        final bytes = await file.readAsBytes();
        final header = bytes.take(4).toList();
        if (!(header[0] == 0x50 && header[1] == 0x4B)) {
          errors.add('Invalid EPUB file format');
        }
      }
      
    } catch (e) {
      errors.add('Error validating file: $e');
    }
    
    return FileValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

class FileValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  FileValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}