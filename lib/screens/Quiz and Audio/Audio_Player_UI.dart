import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback onPlay; // Callback to trigger play action.
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
      await _audioPlayer.setUrl(widget.audioUrl);
    } catch (e) {
      print("Error loading audio source: $e");
      // Handle error appropriately, e.g., show an error message
    }
  }

  // Use didUpdateWidget to trigger play/pause based on the isPlaying prop.
  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioUrl != oldWidget.audioUrl) {
      _initAudioPlayer(); // Reload audio if the URL changes
    }
    _handlePlayPause();
  }

  void _handlePlayPause() {
    if (widget.isPlaying) {
      _audioPlayer.play();
    } else {
      _audioPlayer.pause();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
              widget.onPlay();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: StreamBuilder<Duration?>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final currentPosition = snapshot.data ?? Duration.zero;
                final totalDuration = _audioPlayer.duration ?? Duration.zero;
                return SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 5,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: currentPosition.inSeconds.toDouble(),
                    max: totalDuration.inSeconds.toDouble(),
                    min: 0,
                    activeColor: Colors.black,
                    inactiveColor: Colors.black12,
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                );
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
          StreamBuilder<Duration?>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final currentPosition = snapshot.data ?? Duration.zero;
              final totalDuration = _audioPlayer.duration ?? Duration.zero;
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

  String _formatDuration(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}