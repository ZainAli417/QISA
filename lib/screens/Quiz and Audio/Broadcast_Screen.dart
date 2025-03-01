import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../providers/topic_provider.dart';
import 'Audio_Player_UI.dart';

class Broadcasting extends StatefulWidget {
  const Broadcasting({super.key});

  @override
  State<Broadcasting> createState() => _Create_LectureState();
}

class _Create_LectureState extends State<Broadcasting> {
  final CreateTopicProvider assignmentProvider = CreateTopicProvider();
  final List<File> _selectedFiles = [];
  bool _isUploading = false;
  List<Map<String, dynamic>> _broadcasts = []; // To store fetched broadcasts
  List<String> audioFiles = [];
  StreamSubscription? _broadcastSubscription;

  AudioPlayer? _currentAudioPlayer; // Currently playing audio player
  String? _currentPlayingAudioUrl; // Track which audio URL is currently playing

  void initState() {
    super.initState();
    _setupBroadcastListener();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'mpeg'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles
              .addAll(result.paths.map((path) => File(path!)).toList());
        });
      } else {
        print("No files selected.");
      }
    } catch (e) {
      print("Error picking files: $e");
    }
  }

  Future<List<String>> _uploadFilesToFirebase() async {
    List<String> downloadUrls = [];
    const broadcaster = 'dummy Coordinator';

    try {
      for (var file in _selectedFiles) {
        final fileName = file.path.split('/').last;
        if (['.mp3', '.wav', '.m4a'].any((ext) => fileName.endsWith(ext))) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('broadcast/$broadcaster/$fileName'); // Folder structure
          final uploadTask = ref.putFile(file);

          // Wait for the upload to complete and get the URL
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          downloadUrls.add(downloadUrl);
        } else {
          print("Unsupported file format for $fileName");
        }
      }
    } catch (e) {
      print("Error uploading files: $e");
    }

    return downloadUrls;
  }

  Future<void> _saveToFirestore(CreateTopicProvider assignmentProvider) async {
    if (_selectedFiles.isEmpty) {
      _showSnackbar_connection(context, 'Please select at least one file!');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final audioUrls = await _uploadFilesToFirebase(); // Upload all files
      const broadcaster = 'dummy Coordinator';

      if (audioUrls.isNotEmpty) {
        final docRef =
            FirebaseFirestore.instance.collection('broadcast_voice').doc();
        await docRef.set({
          'AudioFiles': audioUrls, // Save all audio URLs as an array
          'Coordinator': broadcaster,
          'CreatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isUploading = false;
          _selectedFiles.clear();
        });

        _showSnackbar_connection(context, 'Broadcast is Live Now!');
      } else {
        _showSnackbar_failed(context, 'Broadcast not uploaded!');
      }
    } catch (e) {
      print("Error saving to Firestore: $e");
      _showSnackbar_failed(context, 'Error uploading files!');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSnackbar_connection(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
        duration: const Duration(seconds: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showSnackbar_failed(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
        duration: const Duration(seconds: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _setupBroadcastListener() {
    final collectionRef =
        FirebaseFirestore.instance.collection('broadcast_voice');

    _broadcastSubscription = collectionRef
        .orderBy('CreatedAt', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        _broadcasts = querySnapshot.docs.map((doc) {
          return {
            'audioFiles': List<String>.from(doc['AudioFiles']),
            'coordinator': doc['Coordinator'],
            'createdAt': doc['CreatedAt'], // Optional for display or sorting
          };
        }).toList();
      });
    });
  }

  void _stopCurrentAudio() {
    if (_currentAudioPlayer != null) {
      _currentAudioPlayer?.pause(); // Pause the current audio
      _currentAudioPlayer?.dispose();
      _currentAudioPlayer = null;
      _currentPlayingAudioUrl = null; // Reset the currently playing audio URL
    }
  }

  void _playAudio(String audioUrl) {
    if (_currentPlayingAudioUrl == audioUrl) {
      // If the same audio is clicked, pause it
      setState(() {
        _currentPlayingAudioUrl = null; // Reset to not playing
      });
    } else {
      setState(() {
        _currentPlayingAudioUrl = audioUrl; // Track currently playing audio URL
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Broadcast/Announce an Audio Message So that Audience in All conference rooms can listen at once",
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8D919E),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black12,
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              weight: 40,
                              size: 25,
                              Icons.cast_outlined,
                              color: Color(0xFF044B89),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFiles.isNotEmpty
                                  ? "${_selectedFiles.length} Audio(s) selected"
                                  : "Broadcast Audio Message",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isUploading
                            ? null
                            : () => _saveToFirestore(assignmentProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF044B89),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isUploading ? "Uploading..." : "Upload",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                    Divider(),
                    Center(

                        child: Text(
                          'List of Live Broadcasts',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),

                    ),
                    Divider(),
                    SizedBox(height: 5,),
                    Column(
                      children: [
                        // Class Teacher Grid
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _broadcasts.length,
                          itemBuilder: (context, index) {
                            final broadcast = _broadcasts[index];

                            return Card(
                              color: Colors.white,
                              shadowColor: Colors.greenAccent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Coordinator Name (Optional)


                                  if (broadcast['audioFiles'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: broadcast['audioFiles']
                                            .map<Widget>((audioUrl) {
                                          return AudioPlayerWidget(
                                            audioUrl: audioUrl,
                                            onPlay: () => _playAudio(audioUrl),
                                            onStop: _stopCurrentAudio,
                                            isPlaying:
                                                _currentPlayingAudioUrl ==
                                                    audioUrl,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _broadcastSubscription?.cancel(); // Stop the listener when the widget is
    _currentAudioPlayer?.dispose(); // Dispose the current audio player
    super.dispose();
  }
}
