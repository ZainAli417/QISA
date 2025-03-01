import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:videosdk_flutter_example/utils/api.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';

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
          });
        }
      }
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }


  /// Saves the assigned teacher data.
  void savedata(String teacher, String meetingId) async {
    try {
      await FirebaseFirestore.instance.collection('meeting_record').doc(meetingId).set({
        'assigned_to': teacher,
        'room_id': meetingId,
        'room_name': 'Zain Ali',
        'elapsed_time': elapsedTime?.inMinutes ?? 'Progress',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting assigned to $teacher')),
      );
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
