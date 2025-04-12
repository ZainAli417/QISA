import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/audio_playback.dart'; // Your AudioPlaybackProvider
import 'Audio_Player_UI.dart'; // Your pre-built audio player widget

/// Bottom sheet that displays both assigned audio and video files.
class RoomAudioVideoBottomSheet extends StatelessWidget {
  final String roomId;
  const RoomAudioVideoBottomSheet({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('meeting_record')
                .doc(roomId)
                .collection('Study_Material')
                .doc('assigned')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final List<String> audioUrls = (data?['audioUrls'] ?? []).cast<String>();
              final List<String> videoUrls = (data?['videoUrls'] ?? []).cast<String>();

              return ListView(
                controller: scrollController,
                children: [
                  if (audioUrls.isNotEmpty) ...[
                    Text('Audio Files', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    ...audioUrls.map((url) {
                      return Consumer<AudioPlaybackProvider>(
                        builder: (context, playbackProvider, child) {
                          final bool isPlaying = (playbackProvider.currentAudioUrl == url);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: AudioPlayerWidget(
                              audioUrl: url,
                              isPlaying: isPlaying,
                              onPlay: () {
                                if (isPlaying) {
                                  playbackProvider.clearCurrentAudio();
                                } else {
                                  playbackProvider.setCurrentAudio(url);
                                }
                              },
                            ),
                          );
                        },
                      );
                    }).toList(),
                    const Divider(thickness: 2, height: 30),
                  ],
                  if (videoUrls.isNotEmpty) ...[
                    Text('Video Files', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    ...videoUrls.map((url) => VideoPlayerItem(videoUrl: url)).toList(),
                  ],
                  if (audioUrls.isEmpty && videoUrls.isEmpty)
                    const Center(child: Text("No study material assigned yet")),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Custom widget for video playback. It includes full playback controls.
class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Refresh to show video when initialized.
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _controller.play() : _controller.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              ),
              Center(
                child: IconButton(
                  iconSize: 50,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    )
        : const Center(child: CircularProgressIndicator());
  }
}
