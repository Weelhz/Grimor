import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/music_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/settings_provider.dart';
import '../components/reader/pdf_reader.dart';
import '../components/reader/epub_reader.dart';
import '../components/reader/music_control_panel.dart';
import '../components/reader/mood_overlay.dart';

class ReaderPage extends StatefulWidget {
  @override
  _ReaderPageState createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  int _currentChapter = 1;
  double _currentPageFraction = 0.0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _setupMoodTriggerListener();
  }

  void _setupMoodTriggerListener() {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    
    syncProvider.setupMoodTriggerListener((moodTrigger) {
      moodProvider.handleMoodTrigger(moodTrigger);
      musicProvider.handleMoodTempoChange(moodTrigger.tempo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        if (bookProvider.currentBook == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No book selected',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a book from your library to start reading',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final book = bookProvider.currentBook!;
        final isEpub = book.filepath.toLowerCase().endsWith('.epub');

        return Stack(
          children: [
            // Background with mood overlay
            Consumer<MoodProvider>(
              builder: (context, moodProvider, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: _buildMoodGradient(moodProvider.currentMoodTrigger),
                  ),
                  child: child,
                );
              },
            ),

            // Book reader
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: isEpub
                  ? EpubReader(
                      book: book,
                      onProgressChange: _handleProgressChange,
                    )
                  : PdfReader(
                      book: book,
                      onProgressChange: _handleProgressChange,
                    ),
            ),

            // Mood overlay
            if (_showControls)
              Consumer<MoodProvider>(
                builder: (context, moodProvider, child) {
                  return MoodOverlay(
                    moodTrigger: moodProvider.currentMoodTrigger,
                  );
                },
              ),

            // Top controls
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              bookProvider.clearCurrentBook();
                            },
                          ),
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: _showReaderSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                'Ch. $_currentChapter',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _currentPageFraction,
                                  onChanged: (value) {
                                    setState(() {
                                      _currentPageFraction = value;
                                    });
                                    _handleProgressChange(_currentChapter, value);
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                '${(_currentPageFraction * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        // Music control panel
                        MusicControlPanel(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  LinearGradient _buildMoodGradient(dynamic moodTrigger) {
    if (moodTrigger == null) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.8),
          Colors.black.withOpacity(0.9),
        ],
      );
    }

    // Create mood-based gradient
    Color moodColor = _getMoodColor(moodTrigger.moodName);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        moodColor.withOpacity(0.3),
        Colors.black.withOpacity(0.9),
      ],
    );
  }

  Color _getMoodColor(String moodName) {
    switch (moodName.toLowerCase()) {
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'excited':
        return Colors.orange;
      case 'calm':
        return Colors.green;
      case 'mysterious':
        return Colors.purple;
      case 'romantic':
        return Colors.pink;
      case 'tense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleProgressChange(int chapter, double pageFraction) {
    setState(() {
      _currentChapter = chapter;
      _currentPageFraction = pageFraction;
    });

    // Save progress locally
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    
    if (bookProvider.currentBook != null) {
      settingsProvider.setReadingProgress(
        bookProvider.currentBook!.id,
        chapter,
        pageFraction,
      );

      // Send progress to server
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      if (syncProvider.isConnected) {
        syncProvider.sendProgressUpdate(
          bookProvider.currentBook!.id,
          1, // preset ID - would need to be dynamic
          chapter,
          pageFraction,
        );
      }
    }
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Font Size'),
              subtitle: const Text('Adjust reading font size'),
              trailing: const Icon(Icons.format_size),
              onTap: () {
                Navigator.pop(context);
                // Would show font size dialog
              },
            ),
            ListTile(
              title: const Text('Background Color'),
              subtitle: const Text('Change reading background'),
              trailing: const Icon(Icons.color_lens),
              onTap: () {
                Navigator.pop(context);
                // Would show color picker
              },
            ),
            ListTile(
              title: const Text('Reading Mode'),
              subtitle: const Text('Day/Night mode settings'),
              trailing: const Icon(Icons.brightness_4),
              onTap: () {
                Navigator.pop(context);
                // Would show reading mode options
              },
            ),
          ],
        ),
      ),
    );
  }
}