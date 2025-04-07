import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

mixin MeetingAppBarLogic<T extends StatefulWidget> on State<T> {
  Duration? elapsedTime;
  Timer? sessionTimer;
  String? selectedTeacher;
  List<String> teacherList = [];

  /// Fetches the list of teachers from Firestore.
  Future<void> fetchTeachers(String meetingId) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('room_metadata')
          .doc('i5NpyLzF5fE1zKyPa9r1') // Use your document path here.
          .get();

      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data.containsKey('teacher_list')) {
          List<dynamic> fetchedTeachers = data['teacher_list'];
          setState(() {
            teacherList = List<String>.from(fetchedTeachers);
            // If selectedTeacher is null and list is not empty, set to first teacher
            if (selectedTeacher == null && teacherList.isNotEmpty) {
              selectedTeacher = teacherList[0];
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  /// Saves the assigned teacher data with null checks and merge option.
  void savedata(String? teacher, String meetingId) async {
    try {
      await FirebaseFirestore.instance.collection('meeting_record').doc(meetingId).set({
        'assigned_to': teacher ?? 'Unassigned',
        'room_id': meetingId ?? 'Unknown',
        'room_name': 'Zain Ali',
        'elapsed_time': elapsedTime?.inMinutes.toString() ?? '0',
      }, SetOptions(merge: true)); // Merge to update instead of overwrite


    } catch (e) {
      print('Error assigning meeting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign meeting')),
      );
    }
  }

  @override
  void dispose() {
    sessionTimer?.cancel();
    super.dispose();
  }
}