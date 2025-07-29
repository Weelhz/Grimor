import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/mood.dart';

class MoodProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  MoodTrigger? _currentMoodTrigger;
  List<MoodReference> _moodReferences = [];
  bool _isLoading = false;
  String? _error;

  MoodTrigger? get currentMoodTrigger => _currentMoodTrigger;
  List<MoodReference> get moodReferences => _moodReferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void handleMoodTrigger(MoodTrigger moodTrigger) {
    _currentMoodTrigger = moodTrigger;
    _logger.i('Mood trigger received: ${moodTrigger.moodName} (tempo: ${moodTrigger.tempo})');
    notifyListeners();
  }

  void loadMoodReferences(List<MoodReference> references) {
    _moodReferences = references;
    _logger.i('Loaded ${references.length} mood references');
    notifyListeners();
  }

  MoodReference? getMoodByName(String moodName) {
    try {
      return _moodReferences.firstWhere(
        (mood) => mood.moodName.toLowerCase() == moodName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  int getTempoForGenre(String moodName, String genre) {
    final mood = getMoodByName(moodName);
    if (mood == null) return 120; // Default tempo

    switch (genre.toLowerCase()) {
      case 'electronic':
        return mood.tempoElectronic;
      case 'classic':
        return mood.tempoClassic;
      case 'lofi':
        return mood.tempoLofi;
      case 'custom':
        return mood.tempoCustom > 0 ? mood.tempoCustom : mood.tempoElectronic;
      default:
        return mood.tempoElectronic;
    }
  }

  void clearCurrentMoodTrigger() {
    _currentMoodTrigger = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}