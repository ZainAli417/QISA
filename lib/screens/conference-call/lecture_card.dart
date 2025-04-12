import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart' ;
import '../BOTTOM_SHEETS/Audio_Player_UI.dart';

class LectureAudioCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final List<String> audioFiles;
  final String docId;
  final bool isTeacher;
  final String? currentPlayingAudioUrl;
  final Function(String) onPlayAudio;

  const LectureAudioCard({
    required this.title,
    required this.description,
    required this.status,
    required this.audioFiles,
    required this.docId,
    required this.isTeacher,
    required this.currentPlayingAudioUrl,
    required this.onPlayAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            if (audioFiles.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: audioFiles.map((audioUrl) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: AudioPlayerWidget(
                      audioUrl: audioUrl,
                      onPlay: () => onPlayAudio(audioUrl),
                      isPlaying: currentPlayingAudioUrl == audioUrl,
                    ),
                  );
                }).toList(),
              )
            else
              const Text('No audio files', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lecture Name', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (isTeacher)
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {},
                child: Text(status, style: const TextStyle(fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  FirebaseFirestore.instance.collection('Study_material').doc(docId).delete();
                },
              ),
            ],
          ),
      ],
    );
  }
}
