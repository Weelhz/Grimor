import 'package:flutter/material.dart';
import '../../models/book.dart';

class EpubReader extends StatefulWidget {
  final Book book;
  final Function(int chapter, double pageFraction) onProgressChange;

  const EpubReader({
    Key? key,
    required this.book,
    required this.onProgressChange,
  }) : super(key: key);

  @override
  _EpubReaderState createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> {
  int _currentChapter = 1;
  int _totalChapters = 10;
  double _chapterProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: PageView.builder(
        onPageChanged: (index) {
          setState(() {
            _currentChapter = index + 1;
            _chapterProgress = 0.0;
          });
          
          widget.onProgressChange(_currentChapter, _chapterProgress);
        },
        itemCount: _totalChapters,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter ${index + 1}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _getChapterContent(index),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getChapterContent(int chapterIndex) {
    // In a real implementation, this would load actual EPUB content
    // For now, we'll show placeholder content that changes based on chapter
    
    final chapterTitles = [
      'The Beginning',
      'A New Journey',
      'Challenges Ahead',
      'The Discovery',
      'Turning Point',
      'The Confrontation',
      'Resolution',
      'New Horizons',
      'The Final Chapter',
      'Epilogue',
    ];
    
    final chapterContents = [
      '''It was a bright cold day in April, and the clocks were striking thirteen. The story begins with our protagonist facing an unusual situation that would change everything.

The morning sun cast long shadows across the empty street, and there was something different in the air. Something that promised adventure, danger, and perhaps even a touch of magic.

As the character walked down the familiar path, little did they know that this would be the last time they would see their old life. The journey ahead would test their courage, challenge their beliefs, and ultimately transform them into someone they never thought they could become.''',
      
      '''The journey had begun in earnest now. With each step forward, the world seemed to shift and change around our protagonist. What had once been familiar now felt foreign and strange.

The path ahead was unclear, shrouded in mist and uncertainty. But there was no turning back now. The decision had been made, and the consequences would have to be faced, whatever they might be.

In the distance, the sound of something approaching could be heard. Whether it was friend or foe remained to be seen, but it was clear that this encounter would be significant.''',
      
      '''The challenges came thick and fast now. Each obstacle seemed more difficult than the last, testing not just physical strength but mental resolve as well.

Our protagonist had to draw upon reserves of courage they didn't know they possessed. The lessons learned in childhood, the wisdom gained through experience, and the support of unexpected allies all played their part.

But perhaps most importantly, they had to learn to trust themselves. To believe that they had the strength to overcome whatever lay ahead, no matter how impossible it might seem.''',
    ];
    
    return '''${chapterTitles[chapterIndex % chapterTitles.length]}

${chapterContents[chapterIndex % chapterContents.length]}

[Content continues with more detailed storytelling, character development, and plot progression...]

The chapter would continue with rich narrative, dialogue, and descriptive passages that would engage the reader and drive the story forward. In a real implementation, this would be loaded from the actual EPUB file structure.''';
  }
}