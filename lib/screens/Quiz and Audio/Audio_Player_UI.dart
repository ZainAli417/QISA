import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback onPlay; // Callback to trigger parent's state update.
  final bool isPlaying; // Indicates if this audio should be playing.

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.onPlay,
    required this.isPlaying,
  }) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // setUrl returns the duration if available.
      await _audioPlayer.setUrl(widget.audioUrl);
      setState(() {}); // Refresh to update slider if duration is loaded.
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the audio URL changes, reload the audio.
    if (widget.audioUrl != oldWidget.audioUrl) {
      _initAudioPlayer();
    }
    // Only trigger play/pause if the playing state has changed.
    if (widget.isPlaying != oldWidget.isPlaying) {
      _handlePlayPause();
    }
  }

  void _handlePlayPause() {
    if (widget.isPlaying) {
      _audioPlayer.play();
    } else {
      _audioPlayer.pause();
      _audioPlayer.seek(Duration.zero); // optional: reset position on stop
    }

  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background color.
        borderRadius: BorderRadius.circular(25), // Rounded corners.
        border: Border.all(
          color: Colors.grey.shade400, // Border color.
          width: 2, // Border width.
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              widget.isPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_arrow_outlined,
              color: widget.isPlaying ? Colors.green : Colors.red,
              size: 30,
            ),
            onPressed: () {
              // Call parent's callback to update the playing state.
              widget.onPlay();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final currentPosition = snapshot.data ?? Duration.zero;
                final totalDuration =
                    _audioPlayer.duration ?? Duration.zero;
                // Show slider only when total duration is greater than zero.
                return totalDuration.inSeconds > 0
                    ? SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 5,
                    thumbShape:
                    RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: currentPosition.inSeconds.toDouble(),
                    max: totalDuration.inSeconds.toDouble(),
                    min: 0,
                    activeColor: Colors.black,
                    inactiveColor: Colors.black12,
                    onChanged: (value) async {
                      await _audioPlayer
                          .seek(Duration(seconds: value.toInt()));
                    },
                  ),
                )
                    : const SizedBox();
              },
            ),
          ),
          IconButton(
            icon: Icon(
              _isLooping ? Icons.repeat_one_rounded : Icons.repeat_outlined,
              color: _isLooping ? Colors.green : Colors.red,
              size: 20,
            ),
            onPressed: () async {
              setState(() {
                _isLooping = !_isLooping;
              });
              await _audioPlayer.setLoopMode(
                  _isLooping ? LoopMode.one : LoopMode.off);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final currentPosition = snapshot.data ?? Duration.zero;
              final totalDuration =
                  _audioPlayer.duration ?? Duration.zero;
              final remainingTime = totalDuration - currentPosition;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _formatDuration(remainingTime),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
