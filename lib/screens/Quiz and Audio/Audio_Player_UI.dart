import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback onPlay; // Callback to handle play action
  final VoidCallback onStop; // Callback to handle play action
  final bool isPlaying; // Track if this audio is currently playing

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.onPlay,
    required this.onStop,
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
    _audioPlayer.setUrl(widget.audioUrl);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_audioPlayer.playing) return; // Prevent duplicate play calls
    await _audioPlayer.play();
  }

  Future<void> _pauseAudio() async {
    if (!_audioPlayer.playing) return; // Prevent duplicate pause calls
    await _audioPlayer.pause();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Synchronize the audio player with the parent's isPlaying state
    if (widget.isPlaying) {
      _playAudio();
    } else {
      _pauseAudio();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(25), // Rounded corners
        border: Border.all(
          color: Colors.grey.shade400, // Border color
          width: 2, // Border width
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
              widget.isPlaying ? widget.onStop() : widget.onPlay();
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
              await _audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
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
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
