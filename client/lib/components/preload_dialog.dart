import 'package:flutter/material.dart';

class PreloadDialog extends StatefulWidget {
  final String bookTitle;
  final VoidCallback onCancel;
  final Future<void> Function(Function(double) onProgress) onPreload;

  const PreloadDialog({
    Key? key,
    required this.bookTitle,
    required this.onCancel,
    required this.onPreload,
  }) : super(key: key);

  @override
  _PreloadDialogState createState() => _PreloadDialogState();
}

class _PreloadDialogState extends State<PreloadDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _currentTask = 'Preparing...';
  bool _isComplete = false;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _startPreload();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startPreload() async {
    try {
      await widget.onPreload((progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _currentTask = _getTaskForProgress(progress);
          });
        }
      });

      if (mounted) {
        setState(() {
          _isComplete = true;
          _currentTask = 'Complete!';
        });

        // Auto-close after success
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _currentTask = 'Error occurred';
        });
      }
    }
  }

  String _getTaskForProgress(double progress) {
    if (progress < 0.1) return 'Preparing...';
    if (progress < 0.3) return 'Downloading book content...';
    if (progress < 0.6) return 'Downloading music tracks...';
    if (progress < 0.8) return 'Downloading background images...';
    if (progress < 0.95) return 'Finalizing cache...';
    return 'Almost ready...';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isComplete || _hasError,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Preparing Book',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Book title
                Text(
                  widget.bookTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Progress indicator
                if (!_hasError) ...[
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        // Background circle
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                        
                        // Progress circle
                        CircularProgressIndicator(
                          value: _isComplete ? 1.0 : _progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isComplete ? Colors.green : Theme.of(context).primaryColor,
                          ),
                        ),
                        
                        // Center icon
                        Center(
                          child: Icon(
                            _isComplete ? Icons.check : Icons.download,
                            color: _isComplete ? Colors.green : Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Error icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Progress percentage
                if (!_hasError && !_isComplete) ...[
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
                
                // Current task
                Text(
                  _currentTask,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _hasError ? Colors.red : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                
                // Error message
                if (_hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Progress bar
                if (!_hasError) ...[
                  LinearProgressIndicator(
                    value: _isComplete ? 1.0 : _progress,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isComplete ? Colors.green : Theme.of(context).primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isComplete && !_hasError) ...[
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                    
                    if (_hasError) ...[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _progress = 0.0;
                            _currentTask = 'Preparing...';
                          });
                          _startPreload();
                        },
                        child: const Text('Retry'),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ],
                    
                    if (_isComplete) ...[
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Continue'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Preload progress widget for embedded use
class PreloadProgress extends StatelessWidget {
  final double progress;
  final String currentTask;
  final bool isComplete;
  final bool hasError;
  final VoidCallback? onRetry;

  const PreloadProgress({
    Key? key,
    required this.progress,
    required this.currentTask,
    this.isComplete = false,
    this.hasError = false,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: isComplete ? 1.0 : progress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hasError
                        ? Colors.red
                        : isComplete
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTask,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              
              if (hasError && onRetry != null) ...[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRetry,
                  tooltip: 'Retry',
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          LinearProgressIndicator(
            value: isComplete ? 1.0 : progress,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              hasError
                  ? Colors.red
                  : isComplete
                      ? Colors.green
                      : Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Preload manager for handling multiple preload operations
class PreloadManager {
  static final Map<String, PreloadOperation> _operations = {};

  static String startPreload({
    required String bookId,
    required String bookTitle,
    required Future<void> Function(Function(double) onProgress) onPreload,
  }) {
    final operationId = '${bookId}_${DateTime.now().millisecondsSinceEpoch}';
    
    _operations[operationId] = PreloadOperation(
      id: operationId,
      bookId: bookId,
      bookTitle: bookTitle,
      status: PreloadStatus.inProgress,
      progress: 0.0,
      startTime: DateTime.now(),
    );

    _executePreload(operationId, onPreload);
    return operationId;
  }

  static Future<void> _executePreload(
    String operationId,
    Future<void> Function(Function(double) onProgress) onPreload,
  ) async {
    final operation = _operations[operationId];
    if (operation == null) return;

    try {
      await onPreload((progress) {
        _operations[operationId] = operation.copyWith(
          progress: progress,
          currentTask: _getTaskForProgress(progress),
        );
      });

      _operations[operationId] = operation.copyWith(
        status: PreloadStatus.completed,
        progress: 1.0,
        currentTask: 'Complete!',
        endTime: DateTime.now(),
      );
    } catch (e) {
      _operations[operationId] = operation.copyWith(
        status: PreloadStatus.failed,
        currentTask: 'Error: $e',
        endTime: DateTime.now(),
      );
    }
  }

  static String _getTaskForProgress(double progress) {
    if (progress < 0.1) return 'Preparing...';
    if (progress < 0.3) return 'Downloading book content...';
    if (progress < 0.6) return 'Downloading music tracks...';
    if (progress < 0.8) return 'Downloading background images...';
    if (progress < 0.95) return 'Finalizing cache...';
    return 'Almost ready...';
  }

  static PreloadOperation? getOperation(String operationId) {
    return _operations[operationId];
  }

  static List<PreloadOperation> getAllOperations() {
    return _operations.values.toList();
  }

  static void removeOperation(String operationId) {
    _operations.remove(operationId);
  }

  static void clearCompleted() {
    _operations.removeWhere((key, value) => 
        value.status == PreloadStatus.completed ||
        value.status == PreloadStatus.failed);
  }
}

// Preload operation model
class PreloadOperation {
  final String id;
  final String bookId;
  final String bookTitle;
  final PreloadStatus status;
  final double progress;
  final String currentTask;
  final DateTime startTime;
  final DateTime? endTime;

  PreloadOperation({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.status,
    required this.progress,
    this.currentTask = 'Preparing...',
    required this.startTime,
    this.endTime,
  });

  PreloadOperation copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    PreloadStatus? status,
    double? progress,
    String? currentTask,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return PreloadOperation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isComplete => status == PreloadStatus.completed;
  bool get isFailed => status == PreloadStatus.failed;
  bool get isInProgress => status == PreloadStatus.inProgress;
}

enum PreloadStatus { inProgress, completed, failed }