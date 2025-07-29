import 'dart:math' as math;
import '../models/mood.dart';

class MoodUtils {
  // Mood intensity mapping
  static const Map<String, double> moodIntensityMap = {
    'calm': 0.2,
    'peaceful': 0.1,
    'sad': 0.3,
    'melancholic': 0.4,
    'happy': 0.7,
    'joyful': 0.8,
    'excited': 0.9,
    'energetic': 0.85,
    'tense': 0.6,
    'suspenseful': 0.65,
    'mysterious': 0.5,
    'dark': 0.45,
    'romantic': 0.4,
    'nostalgic': 0.35,
    'whimsical': 0.6,
    'epic': 0.8,
    'action': 0.85,
  };

  // Color mapping for moods
  static const Map<String, List<int>> moodColorMap = {
    'calm': [76, 175, 80], // Green
    'peaceful': [129, 199, 132], // Light Green
    'sad': [33, 150, 243], // Blue
    'melancholic': [63, 81, 181], // Indigo
    'happy': [255, 193, 7], // Amber
    'joyful': [255, 235, 59], // Yellow
    'excited': [244, 67, 54], // Red
    'energetic': [233, 30, 99], // Pink
    'tense': [183, 28, 28], // Dark Red
    'suspenseful': [255, 87, 34], // Deep Orange
    'mysterious': [156, 39, 176], // Purple
    'dark': [97, 97, 97], // Grey
    'romantic': [240, 98, 146], // Pink
    'nostalgic': [255, 152, 0], // Orange
    'whimsical': [139, 195, 74], // Light Green
    'epic': [121, 85, 72], // Brown
    'action': [255, 61, 0], // Red Orange
  };

  // Get mood intensity (0.0 to 1.0)
  static double getMoodIntensity(String moodName) {
    return moodIntensityMap[moodName.toLowerCase()] ?? 0.5;
  }

  // Get mood color as RGB values
  static List<int> getMoodColor(String moodName) {
    return moodColorMap[moodName.toLowerCase()] ?? [158, 158, 158];
  }

  // Get mood color as hex string
  static String getMoodColorHex(String moodName) {
    final rgb = getMoodColor(moodName);
    return '#${rgb[0].toRadixString(16).padLeft(2, '0')}'
        '${rgb[1].toRadixString(16).padLeft(2, '0')}'
        '${rgb[2].toRadixString(16).padLeft(2, '0')}';
  }

  // Calculate mood similarity (0.0 to 1.0)
  static double calculateMoodSimilarity(String mood1, String mood2) {
    if (mood1.toLowerCase() == mood2.toLowerCase()) return 1.0;
    
    final intensity1 = getMoodIntensity(mood1);
    final intensity2 = getMoodIntensity(mood2);
    
    // Calculate similarity based on intensity difference
    final intensityDiff = (intensity1 - intensity2).abs();
    final intensitySimilarity = 1.0 - intensityDiff;
    
    // Check for mood category similarity
    final category1 = getMoodCategory(mood1);
    final category2 = getMoodCategory(mood2);
    final categorySimilarity = category1 == category2 ? 1.0 : 0.5;
    
    // Combined similarity score
    return (intensitySimilarity * 0.6) + (categorySimilarity * 0.4);
  }

  // Get mood category
  static String getMoodCategory(String moodName) {
    final mood = moodName.toLowerCase();
    
    if (['calm', 'peaceful', 'relaxed'].contains(mood)) return 'calm';
    if (['sad', 'melancholic', 'depressed'].contains(mood)) return 'sad';
    if (['happy', 'joyful', 'cheerful'].contains(mood)) return 'happy';
    if (['excited', 'energetic', 'thrilled'].contains(mood)) return 'energetic';
    if (['tense', 'suspenseful', 'anxious'].contains(mood)) return 'tense';
    if (['mysterious', 'dark', 'eerie'].contains(mood)) return 'mysterious';
    if (['romantic', 'loving', 'intimate'].contains(mood)) return 'romantic';
    if (['nostalgic', 'wistful', 'reminiscent'].contains(mood)) return 'nostalgic';
    if (['whimsical', 'playful', 'quirky'].contains(mood)) return 'whimsical';
    if (['epic', 'heroic', 'grand'].contains(mood)) return 'epic';
    if (['action', 'intense', 'dramatic'].contains(mood)) return 'action';
    
    return 'neutral';
  }

  // Apply mood sensitivity scaling
  static double applyMoodSensitivity({
    required double baseMoodIntensity,
    required double sensitivity,
  }) {
    // Sensitivity ranges from 0.1 to 2.0
    // 1.0 = normal, < 1.0 = reduced, > 1.0 = enhanced
    final adjustedIntensity = baseMoodIntensity * sensitivity;
    
    // Clamp to valid range
    return math.max(0.0, math.min(1.0, adjustedIntensity));
  }

  // Get mood transition type based on mood change
  static String getTransitionType(String fromMood, String toMood) {
    final fromIntensity = getMoodIntensity(fromMood);
    final toIntensity = getMoodIntensity(toMood);
    final fromCategory = getMoodCategory(fromMood);
    final toCategory = getMoodCategory(toMood);
    
    // If same category, use fade
    if (fromCategory == toCategory) return 'fade';
    
    // If intensity difference is large, use crossfade
    if ((fromIntensity - toIntensity).abs() > 0.4) return 'crossfade';
    
    // For dramatic changes, use immediate
    if (_isDramaticChange(fromMood, toMood)) return 'immediate';
    
    // Default to fade
    return 'fade';
  }

  // Check if mood change is dramatic
  static bool _isDramaticChange(String fromMood, String toMood) {
    final dramaticPairs = [
      ['calm', 'excited'],
      ['sad', 'happy'],
      ['peaceful', 'action'],
      ['romantic', 'tense'],
      ['nostalgic', 'energetic'],
    ];
    
    for (final pair in dramaticPairs) {
      if ((pair[0] == fromMood.toLowerCase() && pair[1] == toMood.toLowerCase()) ||
          (pair[1] == fromMood.toLowerCase() && pair[0] == toMood.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  // Generate mood gradient colors
  static List<List<int>> generateMoodGradient(String moodName, {int steps = 5}) {
    final baseColor = getMoodColor(moodName);
    final intensity = getMoodIntensity(moodName);
    
    final gradient = <List<int>>[];
    
    for (int i = 0; i < steps; i++) {
      final factor = i / (steps - 1);
      final alpha = intensity * (1.0 - factor * 0.5);
      
      gradient.add([
        (baseColor[0] * alpha).round(),
        (baseColor[1] * alpha).round(),
        (baseColor[2] * alpha).round(),
      ]);
    }
    
    return gradient;
  }

  // Get complementary mood suggestions
  static List<String> getComplementaryMoods(String moodName) {
    final category = getMoodCategory(moodName);
    
    switch (category) {
      case 'calm':
        return ['peaceful', 'relaxed', 'serene'];
      case 'sad':
        return ['melancholic', 'nostalgic', 'wistful'];
      case 'happy':
        return ['joyful', 'cheerful', 'upbeat'];
      case 'energetic':
        return ['excited', 'thrilled', 'dynamic'];
      case 'tense':
        return ['suspenseful', 'anxious', 'dramatic'];
      case 'mysterious':
        return ['dark', 'eerie', 'enigmatic'];
      case 'romantic':
        return ['loving', 'intimate', 'passionate'];
      case 'nostalgic':
        return ['wistful', 'reminiscent', 'sentimental'];
      case 'whimsical':
        return ['playful', 'quirky', 'lighthearted'];
      case 'epic':
        return ['heroic', 'grand', 'majestic'];
      case 'action':
        return ['intense', 'dramatic', 'powerful'];
      default:
        return ['neutral', 'balanced', 'moderate'];
    }
  }

  // Calculate mood transition duration
  static Duration calculateTransitionDuration({
    required String fromMood,
    required String toMood,
    required String transitionType,
  }) {
    final intensity1 = getMoodIntensity(fromMood);
    final intensity2 = getMoodIntensity(toMood);
    final intensityDiff = (intensity1 - intensity2).abs();
    
    // Base duration based on transition type
    int baseMilliseconds;
    switch (transitionType) {
      case 'immediate':
        baseMilliseconds = 100;
        break;
      case 'fade':
        baseMilliseconds = 1000;
        break;
      case 'crossfade':
        baseMilliseconds = 1500;
        break;
      default:
        baseMilliseconds = 1000;
    }
    
    // Adjust based on intensity difference
    final adjustedDuration = baseMilliseconds + (intensityDiff * 500).round();
    
    return Duration(milliseconds: adjustedDuration);
  }

  // Get mood-appropriate background opacity
  static double getMoodBackgroundOpacity(String moodName) {
    final intensity = getMoodIntensity(moodName);
    final category = getMoodCategory(moodName);
    
    // Darker moods need higher opacity
    if (['dark', 'mysterious', 'tense'].contains(category)) {
      return 0.8 + (intensity * 0.2);
    }
    
    // Lighter moods need lower opacity
    if (['happy', 'joyful', 'whimsical'].contains(category)) {
      return 0.4 + (intensity * 0.3);
    }
    
    // Default opacity based on intensity
    return 0.5 + (intensity * 0.3);
  }

  // Validate mood trigger parameters
  static bool isValidMoodTrigger({
    required int chapter,
    required double pageFraction,
    required String moodName,
  }) {
    if (chapter < 1) return false;
    if (pageFraction < 0.0 || pageFraction > 1.0) return false;
    if (moodName.isEmpty) return false;
    
    return true;
  }

  // Get mood icon suggestion
  static String getMoodIcon(String moodName) {
    final category = getMoodCategory(moodName);
    
    switch (category) {
      case 'calm':
        return '🌿';
      case 'sad':
        return '😢';
      case 'happy':
        return '😊';
      case 'energetic':
        return '⚡';
      case 'tense':
        return '⚠️';
      case 'mysterious':
        return '🔮';
      case 'romantic':
        return '💕';
      case 'nostalgic':
        return '🕰️';
      case 'whimsical':
        return '✨';
      case 'epic':
        return '🏆';
      case 'action':
        return '🔥';
      default:
        return '🎭';
    }
  }
}

// Mood analysis utilities
class MoodAnalysis {
  static Map<String, dynamic> analyzeMoodSequence(List<MoodTrigger> triggers) {
    if (triggers.isEmpty) {
      return {
        'total_triggers': 0,
        'mood_variety': 0.0,
        'average_intensity': 0.0,
        'dominant_category': 'none',
        'transition_quality': 'none',
      };
    }
    
    // Count mood categories
    final categoryCount = <String, int>{};
    double totalIntensity = 0.0;
    
    for (final trigger in triggers) {
      final category = MoodUtils.getMoodCategory(trigger.moodName);
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      totalIntensity += MoodUtils.getMoodIntensity(trigger.moodName);
    }
    
    // Find dominant category
    String dominantCategory = 'none';
    int maxCount = 0;
    categoryCount.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantCategory = category;
      }
    });
    
    // Calculate variety (number of unique categories / total possible)
    final variety = categoryCount.length / moodIntensityMap.length;
    
    // Calculate average intensity
    final averageIntensity = totalIntensity / triggers.length;
    
    // Analyze transition quality
    final transitionQuality = _analyzeTransitionQuality(triggers);
    
    return {
      'total_triggers': triggers.length,
      'mood_variety': variety,
      'average_intensity': averageIntensity,
      'dominant_category': dominantCategory,
      'transition_quality': transitionQuality,
      'category_distribution': categoryCount,
    };
  }
  
  static String _analyzeTransitionQuality(List<MoodTrigger> triggers) {
    if (triggers.length < 2) return 'insufficient_data';
    
    int smoothTransitions = 0;
    int dramaticTransitions = 0;
    
    for (int i = 1; i < triggers.length; i++) {
      final fromMood = triggers[i - 1].moodName;
      final toMood = triggers[i].moodName;
      final similarity = MoodUtils.calculateMoodSimilarity(fromMood, toMood);
      
      if (similarity > 0.7) {
        smoothTransitions++;
      } else if (similarity < 0.3) {
        dramaticTransitions++;
      }
    }
    
    final totalTransitions = triggers.length - 1;
    final smoothRatio = smoothTransitions / totalTransitions;
    final dramaticRatio = dramaticTransitions / totalTransitions;
    
    if (smoothRatio > 0.7) return 'smooth';
    if (dramaticRatio > 0.5) return 'dramatic';
    return 'balanced';
  }
}