import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class StudyMaterialBottomSheet extends StatefulWidget {
  final String roomId;

  const StudyMaterialBottomSheet({Key? key, required this.roomId}) : super(key: key);

  @override
  State<StudyMaterialBottomSheet> createState() => _StudyMaterialBottomSheetState();
}

class _StudyMaterialBottomSheetState extends State<StudyMaterialBottomSheet> {
  List<Reference> audioFiles = [];
  List<Reference> videoFiles = [];
  Set<String> selectedAudioUrls = {};
  Set<String> selectedVideoUrls = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('study_materials');
      final listResult = await storageRef.listAll();

      for (var file in listResult.items) {
        final name = file.name.toLowerCase();
        if (name.endsWith('.mp3') || name.endsWith('.wav') || name.endsWith('.m4a')) {
          audioFiles.add(file);
        } else if (name.endsWith('.mp4') || name.endsWith('.mov') || name.endsWith('.avi')) {
          videoFiles.add(file);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching files: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> submitSelectedFiles() async {
    try {
      if (selectedAudioUrls.isEmpty && selectedVideoUrls.isEmpty) {
        debugPrint('No files selected.');
        return;
      }

      // Debug prints to inspect the selected sets:
      debugPrint('Selected Audio URLs: $selectedAudioUrls');
      debugPrint('Selected Video URLs: $selectedVideoUrls');

      final docRef = FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(widget.roomId)
          .collection('Study_Material')
          .doc('assigned'); // Using fixed doc id 'assigned'

      await docRef.set({
        'audioUrls': selectedAudioUrls.toList(),
        'videoUrls': selectedVideoUrls.toList(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study material assigned successfully')),
      );
    } catch (e) {
      debugPrint('Error submitting files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget buildFileList(List<Reference> files, Set<String> selectedSet, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        ...files.map((fileRef) => FutureBuilder<String>(
          future: fileRef.getDownloadURL(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final fileUrl = snapshot.data!.trim();
            final fileName = fileRef.name;
            final isSelected = selectedSet.contains(fileUrl);

            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(fileName, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (_) {
                  setState(() {
                    if (isSelected) {
                      selectedSet.remove(fileUrl);
                      debugPrint('Removed: $fileUrl');
                    } else {
                      selectedSet.add(fileUrl);
                      debugPrint('Added: $fileUrl');
                    }
                  });
                },
              ),
            );
          },
        ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Materials to Assign',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  buildFileList(audioFiles, selectedAudioUrls, 'Audio Files'),
                  const Divider(thickness: 1.2),
                  buildFileList(videoFiles, selectedVideoUrls, 'Video Files'),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: (selectedAudioUrls.isNotEmpty || selectedVideoUrls.isNotEmpty) ? submitSelectedFiles : null,
              icon: const Icon(Icons.upload_file),
              label: const Text('Assign to Room'),
            ),
          ],
        ),
      ),
    );
  }
}
