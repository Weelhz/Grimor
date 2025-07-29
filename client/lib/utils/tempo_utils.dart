import 'dart:math' as math;
import '../models/mood.dart';
import '../models/music.dart';

class TempoUtils {
  // Genre-based tempo mapping
  static const Map<String, String> genreToMoodGenre = {
    'electronic': 'electronic',
    'edm': 'electronic',
    'synthwave': 'electronic',
    'ambient': 'electronic',
    'classical': 'classic',
    'orchestral': 'classic',
    'piano': 'classic',
    'strings': 'classic',
    'lofi': 'lofi',
    'chill': 'lofi',
    'jazz': 'lofi',
    'acoustic': 'lofi',
  };

  // Calculate target tempo based on mood and music genre
  static int calculateTargetTempo({
    required MoodReference mood,
    required Music music,
    double sensitivity = 1.0,
  }) {
    // Get the appropriate tempo from mood reference based on music genre
    final moodGenre = _getMoodGenreFromMusicGenre(music.genre ?? 'lofi');
    int baseTempo = _getTempoForMoodGenre(mood, moodGenre);
    
    // If custom tempo is set, use it
    if (mood.tempoCustom > 0) {
      baseTempo = mood.tempoCustom;
    }
    
    // Apply sensitivity scaling
    final tempoChange = (baseTempo - music.initialTempo) * sensitivity;
    final targetTempo = music.initialTempo + tempoChange.round();
    
    // Clamp to reasonable bounds (40-200 BPM)
    return math.max(40, math.min(200, targetTempo));
  }

  // Get mood genre from music genre
  static String _getMoodGenreFromMusicGenre(String musicGenre) {
    final normalizedGenre = musicGenre.toLowerCase();
    
    for (final entry in genreToMoodGenre.entries) {
      if (normalizedGenre.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'lofi'; // Default to lofi if no match
  }

  // Get tempo for specific mood genre
  static int _getTempoForMoodGenre(MoodReference mood, String moodGenre) {
    switch (moodGenre) {
      case 'electronic':
        return mood.tempoElectronic;
      case 'classic':
        return mood.tempoClassic;
      case 'lofi':
        return mood.tempoLofi;
      default:
        return mood.tempoLofi;
    }
  }

  // Calculate tempo change percentage
  static double calculateTempoChangePercentage({
    required int originalTempo,
    required int targetTempo,
  }) {
    if (originalTempo == 0) return 0.0;
    return (targetTempo - originalTempo) / originalTempo;
  }

  // Generate smooth tempo transition values
  static List<int> generateTempoTransition({
    required int fromTempo,
    required int toTempo,
    required int steps,
  }) {
    if (steps <= 1) return [toTempo];
    
    final List<int> tempos = [];
    final double stepSize = (toTempo - fromTempo) / (steps - 1);
    
    for (int i = 0; i < steps; i++) {
      final tempo = fromTempo + (stepSize * i).round();
      tempos.add(math.max(40, math.min(200, tempo)));
    }
    
    return tempos;
  }

  // Calculate playback speed multiplier from tempo
  static double calculatePlaybackSpeed({
    required int originalTempo,
    required int targetTempo,
  }) {
    if (originalTempo == 0) return 1.0;
    
    final speed = targetTempo / originalTempo;
    
    // Clamp speed to reasonable bounds (0.5x to 2.0x)
    return math.max(0.5, math.min(2.0, speed));
  }

  // Get tempo category for display
  static String getTempoCategory(int tempo) {
    if (tempo < 60) return 'Very Slow';
    if (tempo < 80) return 'Slow';
    if (tempo < 100) return 'Moderate';
    if (tempo < 120) return 'Medium';
    if (tempo < 140) return 'Fast';
    if (tempo < 160) return 'Very Fast';
    return 'Extremely Fast';
  }

  // Get appropriate tempo for reading activity
  static int getReadingTempo(String activity) {
    switch (activity.toLowerCase()) {
      case 'deep_focus':
        return 60;
      case 'casual_reading':
        return 80;
      case 'study':
        return 70;
      case 'relaxation':
        return 50;
      case 'commute':
        return 90;
      default:
        return 75;
    }
  }

  // Calculate tempo based on reading speed
  static int calculateTempoFromReadingSpeed({
    required double wordsPerMinute,
    required String contentType,
  }) {
    // Base tempo calculation from reading speed
    int baseTempo = (wordsPerMinute * 0.3).round();
    
    // Adjust based on content type
    switch (contentType.toLowerCase()) {
      case 'fiction':
        baseTempo = (baseTempo * 0.9).round();
        break;
      case 'non_fiction':
        baseTempo = (baseTempo * 0.8).round();
        break;
      case 'technical':
        baseTempo = (baseTempo * 0.7).round();
        break;
      case 'poetry':
        baseTempo = (baseTempo * 0.6).round();
        break;
    }
    
    // Clamp to reasonable bounds
    return math.max(40, math.min(120, baseTempo));
  }

  // Validate tempo value
  static bool isValidTempo(int tempo) {
    return tempo >= 40 && tempo <= 200;
  }

  // Get tempo adjustment suggestions
  static List<TempoSuggestion> getTempoSuggestions({
    required int currentTempo,
    required String moodName,
    required String musicGenre,
  }) {
    final suggestions = <TempoSuggestion>[];
    
    // Mood-based suggestions
    if (moodName.toLowerCase().contains('calm') || moodName.toLowerCase().contains('peaceful')) {
      if (currentTempo > 80) {
        suggestions.add(TempoSuggestion(
          tempo: 70,
          reason: 'Slower tempo for calm mood',
          priority: 'high',
        ));
      }
    } else if (moodName.toLowerCase().contains('excited') || moodName.toLowerCase().contains('action')) {
      if (currentTempo < 120) {
        suggestions.add(TempoSuggestion(
          tempo: 130,
          reason: 'Faster tempo for energetic mood',
          priority: 'medium',
        ));
      }
    }
    
    // Genre-based suggestions
    if (musicGenre.toLowerCase().contains('classical')) {
      if (currentTempo > 100) {
        suggestions.add(TempoSuggestion(
          tempo: 90,
          reason: 'Appropriate tempo for classical music',
          priority: 'low',
        ));
      }
    }
    
    return suggestions;
  }
}

class TempoSuggestion {
  final int tempo;
  final String reason;
  final String priority;

  TempoSuggestion({
    required this.tempo,
    required this.reason,
    required this.priority,
  });
}

// Tempo interpolation for smooth transitions
class TempoInterpolator {
  static double easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  static double easeIn(double t) {
    return t * t;
  }

  static double easeOut(double t) {
    return t * (2 - t);
  }

  static double linear(double t) {
    return t;
  }
}

// Tempo analysis utilities
class TempoAnalysis {
  static Map<String, dynamic> analyzeTempo({
    required int tempo,
    required String genre,
    required String mood,
  }) {
    return {
      'tempo': tempo,
      'category': TempoUtils.getTempoCategory(tempo),
      'is_valid': TempoUtils.isValidTempo(tempo),
      'genre_appropriate': _isGenreAppropriate(tempo, genre),
      'mood_appropriate': _isMoodAppropriate(tempo, mood),
      'energy_level': _calculateEnergyLevel(tempo),
      'recommendations': TempoUtils.getTempoSuggestions(
        currentTempo: tempo,
        moodName: mood,
        musicGenre: genre,
      ),
    };
  }

  static bool _isGenreAppropriate(int tempo, String genre) {
    switch (genre.toLowerCase()) {
      case 'classical':
        return tempo >= 60 && tempo <= 120;
      case 'electronic':
        return tempo >= 100 && tempo <= 160;
      case 'lofi':
        return tempo >= 60 && tempo <= 100;
      case 'jazz':
        return tempo >= 80 && tempo <= 140;
      default:
        return true;
    }
  }

  static bool _isMoodAppropriate(int tempo, String mood) {
    switch (mood.toLowerCase()) {
      case 'calm':
      case 'peaceful':
        return tempo <= 80;
      case 'excited':
      case 'energetic':
        return tempo >= 120;
      case 'sad':
      case 'melancholic':
        return tempo <= 70;
      case 'happy':
      case 'joyful':
        return tempo >= 100;
      default:
        return true;
    }
  }

  static String _calculateEnergyLevel(int tempo) {
    if (tempo < 70) return 'Low';
    if (tempo < 100) return 'Medium-Low';
    if (tempo < 130) return 'Medium';
    if (tempo < 160) return 'Medium-High';
    return 'High';
  }
}