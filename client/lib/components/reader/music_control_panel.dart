import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/settings_provider.dart';

class MusicControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current music info
              if (musicProvider.currentMusic != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        musicProvider.currentMusic!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (musicProvider.currentMusic!.genre != null)
                        Text(
                          musicProvider.currentMusic!.genre!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous track (placeholder)
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () {
                      // Would implement previous track functionality
                    },
                  ),
                  
                  // Play/Pause button
                  IconButton(
                    icon: Icon(
                      musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      if (musicProvider.isPlaying) {
                        musicProvider.pause();
                      } else {
                        musicProvider.resume();
                      }
                    },
                  ),
                  
                  // Next track (placeholder)
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () {
                      // Would implement next track functionality
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Progress bar
              if (musicProvider.currentMusic != null)
                Column(
                  children: [
                    Slider(
                      value: musicProvider.position.inMilliseconds.toDouble(),
                      max: musicProvider.duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        musicProvider.seek(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(musicProvider.position),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(musicProvider.duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              // Volume and tempo controls
              Row(
                children: [
                  // Volume control
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.volume_down, color: Colors.white, size: 20),
                        Expanded(
                          child: Consumer<SettingsProvider>(
                            builder: (context, settingsProvider, child) {
                              return Slider(
                                value: settingsProvider.musicVolume.toDouble(),
                                min: 0,
                                max: 100,
                                onChanged: (value) {
                                  settingsProvider.musicVolume = value.toInt();
                                  musicProvider.setVolume(value / 100);
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withOpacity(0.3),
                              );
                            },
                          ),
                        ),
                        const Icon(Icons.volume_up, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Tempo control
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white, size: 20),
                        Expanded(
                          child: Slider(
                            value: musicProvider.tempo,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            onChanged: (value) {
                              musicProvider.setTempo(value);
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          '${musicProvider.tempo.toStringAsFixed(1)}x',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Music loading indicator
              if (musicProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}