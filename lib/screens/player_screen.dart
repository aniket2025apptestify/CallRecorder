import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/recording.dart';
import '../providers/recording_provider.dart';

class PlayerScreen extends StatefulWidget {
  final Recording recording;

  const PlayerScreen({super.key, required this.recording});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.recording.filePath);
      if (await file.exists()) {
        await _audioPlayer.setFilePath(widget.recording.filePath);
        _duration = _audioPlayer.duration ?? Duration.zero;
        _isLoaded = true;

        _audioPlayer.positionStream.listen((pos) {
          if (mounted) setState(() => _position = pos);
        });

        _audioPlayer.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
              if (state.processingState == ProcessingState.completed) {
                _isPlaying = false;
                _position = Duration.zero;
                _audioPlayer.seek(Duration.zero);
                _audioPlayer.pause();
              }
            });
          }
        });

        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(recording.timestamp);
    final timeStr = DateFormat('hh:mm a').format(recording.timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Playback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareRecording,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE94560)),
            onPressed: _deleteRecording,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Phone number display
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFF533483)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                recording.isIncoming ? Icons.call_received : Icons.call_made,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              recording.phoneNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$dateStr • $timeStr',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // Info badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoBadge(
                  recording.isIncoming ? 'Incoming' : 'Outgoing',
                  recording.isIncoming ? Icons.call_received : Icons.call_made,
                  recording.isIncoming ? const Color(0xFF48C9B0) : const Color(0xFFE94560),
                ),
                const SizedBox(width: 12),
                _infoBadge(
                  recording.audioSource == 'VOICE_CALL' ? 'Both Sides' : 'Mic Only',
                  recording.audioSource == 'VOICE_CALL' ? Icons.people : Icons.mic,
                  recording.audioSource == 'VOICE_CALL'
                      ? const Color(0xFF48C9B0)
                      : const Color(0xFFE94560),
                ),
                const SizedBox(width: 12),
                _infoBadge(
                  recording.formattedFileSize,
                  Icons.storage,
                  const Color(0xFF533483),
                ),
              ],
            ),

            const Spacer(flex: 2),

            // Progress bar
            if (_isLoaded) ...[
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: const Color(0xFFE94560),
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                  thumbColor: const Color(0xFFE94560),
                  overlayColor: const Color(0xFFE94560).withOpacity(0.2),
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble().clamp(
                    0,
                    _duration.inMilliseconds.toDouble(),
                  ),
                  max: _duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind 10s
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                  onPressed: _isLoaded
                      ? () {
                          final newPos = _position - const Duration(seconds: 10);
                          _audioPlayer.seek(
                            newPos < Duration.zero ? Duration.zero : newPos,
                          );
                        }
                      : null,
                ),
                const SizedBox(width: 20),
                // Play/Pause
                GestureDetector(
                  onTap: _isLoaded ? _togglePlay : null,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE94560), Color(0xFF533483)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE94560).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Forward 10s
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                  onPressed: _isLoaded
                      ? () {
                          final newPos = _position + const Duration(seconds: 10);
                          _audioPlayer.seek(
                            newPos > _duration ? _duration : newPos,
                          );
                        }
                      : null,
                ),
              ],
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _shareRecording() {
    Share.shareXFiles([XFile(widget.recording.filePath)],
        text: 'Call recording with ${widget.recording.phoneNumber}');
  }

  void _deleteRecording() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Recording?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete this recording.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<RecordingProvider>().deleteRecording(widget.recording);
      if (mounted) Navigator.pop(context);
    }
  }
}
