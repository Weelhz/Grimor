import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../api/music_api.dart';
import '../models/music.dart';
import '../models/playlist.dart';
import '../models/mood.dart';
import '../utils/tempo_utils.dart';
import '../services/file_service.dart';

class MusicProvider with ChangeNotifier {
  final MusicApi _musicApi = MusicApi();
  final FileService _fileService = FileService.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Music state
  List<Music> _musicList = [];
  List<Playlist> _playlists = [];
  Music? _currentMusic;
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;
  
  // Playback state
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 0.7;
  double _playbackSpeed = 1.0;
  
  // Mood-based adjustments
  MoodReference? _currentMood;
  double _moodSensitivity = 1.0;
  
  // Getters
  List<Music> get musicList => _musicList;
  List<Playlist> get playlists => _playlists;
  Music? get currentMusic => _currentMusic;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  MoodReference? get currentMood => _currentMood;
  double get moodSensitivity => _moodSensitivity;
  
  // Initialize music provider
  Future<void> initialize() async {
    await _setupAudioPlayer();
    await loadMusic();
    await loadPlaylists();
  }
  
  // Setup audio player
  Future<void> _setupAudioPlayer() async {
    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    
    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });
    
    // Listen to playback events
    _audioPlayer.playbackEventStream.listen((event) {
      _isPlaying = _audioPlayer.playing;
      notifyListeners();
    });
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }
  
  // Load music from API
  Future<void> loadMusic() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _musicList = await _musicApi.getAllMusic();
    } catch (e) {
      print('Error loading music: $e');
      // Load from local storage as fallback
      _musicList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load playlists from API
  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _playlists = await _musicApi.getUserPlaylists();
    } catch (e) {
      print('Error loading playlists: $e');
      // Load from local storage as fallback
      _playlists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Play music
  Future<void> playMusic(Music music) async {
    try {
      _currentMusic = music;
      
      // Get music file (cached or download)
      final musicFile = await _fileService.getMusicFile(music.id.toString());
      String audioUrl;
      
      if (musicFile != null) {
        audioUrl = musicFile.path;
      } else {
        // Get signed URL from server
        audioUrl = await _musicApi.getMusicSignedUrl(music.id);
      }
      
      // Set audio source
      await _audioPlayer.setUrl(audioUrl);
      
      // Apply mood-based tempo adjustments
      if (_currentMood != null) {
        _applyMoodAdjustments(music, _currentMood!);
      }
      
      // Start playback
      await _audioPlayer.play();
      
      notifyListeners();
    } catch (e) {
      print('Error playing music: $e');
      // Handle playback error
    }
  }
  
  // Play playlist
  Future<void> playPlaylist(Playlist playlist) async {
    _currentPlaylist = playlist;
    
    if (playlist.tracks.isNotEmpty) {
      final firstTrack = playlist.tracks.first;
      if (firstTrack.music != null) {
        await playMusic(firstTrack.music!);
      }
    }
    
    notifyListeners();
  }
  
  // Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
    notifyListeners();
  }
  
  // Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
    notifyListeners();
  }
  
  // Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentMusic = null;
    _currentPosition = Duration.zero;
    notifyListeners();
  }
  
  // Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    notifyListeners();
  }
  
  // Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }
  
  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    await _audioPlayer.setSpeed(_playbackSpeed);
    notifyListeners();
  }
  
  // Toggle shuffle
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }
  
  // Toggle repeat
  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }
  
  // Skip to next track
  Future<void> skipToNext() async {
    if (_currentPlaylist != null && _currentPlaylist!.tracks.isNotEmpty) {
      final currentIndex = _getCurrentTrackIndex();
      if (currentIndex != -1) {
        int nextIndex;
        
        if (_isShuffleEnabled) {
          nextIndex = _getRandomTrackIndex();
        } else {
          nextIndex = (currentIndex + 1) % _currentPlaylist!.tracks.length;
        }
        
        final nextTrack = _currentPlaylist!.tracks[nextIndex];
        if (nextTrack.music != null) {
          await playMusic(nextTrack.music!);
        }
      }
    }
  }
  
  // Skip to previous track
  Future<void> skipToPrevious() async {
    if (_currentPlaylist != null && _currentPlaylist!.tracks.isNotEmpty) {
      final currentIndex = _getCurrentTrackIndex();
      if (currentIndex != -1) {
        int prevIndex;
        
        if (_isShuffleEnabled) {
          prevIndex = _getRandomTrackIndex();
        } else {
          prevIndex = (currentIndex - 1 + _currentPlaylist!.tracks.length) % 
                     _currentPlaylist!.tracks.length;
        }
        
        final prevTrack = _currentPlaylist!.tracks[prevIndex];
        if (prevTrack.music != null) {
          await playMusic(prevTrack.music!);
        }
      }
    }
  }
  
  // Get current track index in playlist
  int _getCurrentTrackIndex() {
    if (_currentPlaylist == null || _currentMusic == null) return -1;
    
    return _currentPlaylist!.tracks.indexWhere(
      (track) => track.musicId == _currentMusic!.id,
    );
  }
  
  // Get random track index
  int _getRandomTrackIndex() {
    if (_currentPlaylist == null || _currentPlaylist!.tracks.isEmpty) return -1;
    
    final random = DateTime.now().millisecondsSinceEpoch % _currentPlaylist!.tracks.length;
    return random;
  }
  
  // Handle track completion
  void _onTrackCompleted() {
    if (_isRepeatEnabled) {
      // Repeat current track
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } else if (_currentPlaylist != null && _currentPlaylist!.tracks.length > 1) {
      // Play next track in playlist
      skipToNext();
    } else {
      // Stop playback
      stop();
    }
  }
  
  // Apply mood-based adjustments
  void _applyMoodAdjustments(Music music, MoodReference mood) {
    // Calculate target tempo based on mood
    final targetTempo = TempoUtils.calculateTargetTempo(
      mood: mood,
      music: music,
      sensitivity: _moodSensitivity,
    );
    
    // Calculate playback speed
    final speed = TempoUtils.calculatePlaybackSpeed(
      originalTempo: music.initialTempo,
      targetTempo: targetTempo,
    );
    
    // Apply speed adjustment
    setPlaybackSpeed(speed);
  }
  
  // Set current mood
  void setCurrentMood(MoodReference mood, double sensitivity) {
    _currentMood = mood;
    _moodSensitivity = sensitivity;
    
    // Apply mood adjustments to current music
    if (_currentMusic != null) {
      _applyMoodAdjustments(_currentMusic!, mood);
    }
    
    notifyListeners();
  }
  
  // Clear current mood
  void clearCurrentMood() {
    _currentMood = null;
    _playbackSpeed = 1.0;
    _audioPlayer.setSpeed(1.0);
    notifyListeners();
  }
  
  // Create new playlist
  Future<void> createPlaylist(String name) async {
    try {
      final playlist = await _musicApi.createPlaylist(name);
      _playlists.add(playlist);
      notifyListeners();
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }
  
  // Update playlist
  Future<void> updatePlaylist(int playlistId, String newName) async {
    try {
      final updatedPlaylist = await _musicApi.updatePlaylist(playlistId, newName);
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = updatedPlaylist;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating playlist: $e');
      rethrow;
    }
  }
  
  // Delete playlist
  Future<void> deletePlaylist(int playlistId) async {
    try {
      await _musicApi.deletePlaylist(playlistId);
      _playlists.removeWhere((p) => p.id == playlistId);
      
      // Clear current playlist if it was deleted
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = null;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting playlist: $e');
      rethrow;
    }
  }
  
  // Add track to playlist
  Future<void> addTrackToPlaylist(int playlistId, int musicId) async {
    try {
      await _musicApi.addTrackToPlaylist(playlistId, musicId);
      
      // Refresh playlist to get updated tracks
      await loadPlaylists();
    } catch (e) {
      print('Error adding track to playlist: $e');
      rethrow;
    }
  }
  
  // Remove track from playlist
  Future<void> removeTrackFromPlaylist(int playlistId, int musicId) async {
    try {
      await _musicApi.removeTrackFromPlaylist(playlistId, musicId);
      
      // Refresh playlist to get updated tracks
      await loadPlaylists();
    } catch (e) {
      print('Error removing track from playlist: $e');
      rethrow;
    }
  }
  
  // Search music
  Future<List<Music>> searchMusic(String query) async {
    try {
      return await _musicApi.searchMusic(query);
    } catch (e) {
      print('Error searching music: $e');
      return [];
    }
  }
  
  // Get music by genre
  Future<List<Music>> getMusicByGenre(String genre) async {
    try {
      return await _musicApi.getMusicByGenre(genre);
    } catch (e) {
      print('Error getting music by genre: $e');
      return [];
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}