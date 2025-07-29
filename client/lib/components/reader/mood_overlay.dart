import 'package:flutter/material.dart';
import '../../models/mood.dart';

class MoodOverlay extends StatefulWidget {
  final MoodTrigger? moodTrigger;

  const MoodOverlay({
    Key? key,
    this.moodTrigger,
  }) : super(key: key);

  @override
  _MoodOverlayState createState() => _MoodOverlayState();
}

class _MoodOverlayState extends State<MoodOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
  }

  @override
  void didUpdateWidget(MoodOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moodTrigger != oldWidget.moodTrigger) {
      if (widget.moodTrigger != null) {
        _animationController.forward();
        _autoHide();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _autoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moodTrigger == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getMoodColor(widget.moodTrigger!.moodName).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mood icon
                    Icon(
                      _getMoodIcon(widget.moodTrigger!.moodName),
                      size: 48,
                      color: Colors.white,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Mood name
                    Text(
                      widget.moodTrigger!.moodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tempo indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tempo: ${widget.moodTrigger!.tempo} BPM',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    
                    // Transition type
                    if (widget.moodTrigger!.transitionType.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getTransitionDescription(widget.moodTrigger!.transitionType),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getMoodColor(String moodName) {
    switch (moodName.toLowerCase()) {
      case 'happy':
        return Colors.orange;
      case 'joyful':
        return Colors.yellow.shade700;
      case 'sad':
        return Colors.blue;
      case 'melancholic':
        return Colors.indigo;
      case 'excited':
        return Colors.red;
      case 'energetic':
        return Colors.pink;
      case 'calm':
        return Colors.green;
      case 'peaceful':
        return Colors.teal;
      case 'mysterious':
        return Colors.purple;
      case 'dark':
        return Colors.grey.shade800;
      case 'romantic':
        return Colors.pink.shade300;
      case 'tense':
        return Colors.red.shade800;
      case 'suspenseful':
        return Colors.deepOrange.shade800;
      case 'nostalgic':
        return Colors.amber.shade700;
      case 'whimsical':
        return Colors.lime;
      default:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(String moodName) {
    switch (moodName.toLowerCase()) {
      case 'happy':
      case 'joyful':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'melancholic':
        return Icons.sentiment_very_dissatisfied;
      case 'excited':
      case 'energetic':
        return Icons.flash_on;
      case 'calm':
      case 'peaceful':
        return Icons.spa;
      case 'mysterious':
      case 'dark':
        return Icons.visibility_off;
      case 'romantic':
        return Icons.favorite;
      case 'tense':
      case 'suspenseful':
        return Icons.warning;
      case 'nostalgic':
        return Icons.history;
      case 'whimsical':
        return Icons.star;
      default:
        return Icons.mood;
    }
  }

  String _getTransitionDescription(String transitionType) {
    switch (transitionType.toLowerCase()) {
      case 'fade':
        return 'Gentle transition';
      case 'crossfade':
        return 'Smooth crossfade';
      case 'immediate':
        return 'Instant change';
      case 'gradual':
        return 'Gradual shift';
      default:
        return 'Mood transition';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}