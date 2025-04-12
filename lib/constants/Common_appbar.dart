import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/role_provider.dart';

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
          .doc('i5NpyLzF5fE1zKyPa9r1') // Replace with your actual document path.
          .get();

      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data.containsKey('teacher_list')) {
          List<dynamic> fetchedTeachers = data['teacher_list'];
          setState(() {
            teacherList = List<String>.from(fetchedTeachers);
            // Do not auto-select a default teacher here.
          });
        }
      }
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  /// Saves the assigned teacher data to Firestore.
  Future<void> savedata(String? teacher, String meetingId) async {
    // Only update the database if a valid teacher selection exists.
    if (teacher == null || teacher.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(meetingId)
          .set({
        'assigned_to': teacher, // Use the valid teacher value.
        'room_id': meetingId,
        'room_name': 'QISA Meeting',
        'elapsed_time': elapsedTime?.inMinutes.toString() ?? '0',
      }, SetOptions(merge: true)); // Merge to update existing fields.
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
