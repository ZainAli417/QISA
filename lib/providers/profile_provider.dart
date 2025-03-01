import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Teacher_model.dart';


class ProfileProvider with ChangeNotifier {
  TeacherData? _teacherData;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TeacherData? get teacherData => _teacherData;
  bool get isLoading => _isLoading;

  // Fetch teacher data based on the logged-in UID
  Future<void> fetchTeacherData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String loggedInUserUid = _auth.currentUser!.uid;;
      print("Logged in user UID: $loggedInUserUid");

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('Teacher_data')
          .where('uid', isEqualTo: loggedInUserUid)
          .limit(1)
          .get();

      print("Number of documents found: ${querySnapshot.docs.length}");

      if (querySnapshot.docs.isNotEmpty) {
        _teacherData = TeacherData.fromMap(querySnapshot.docs.first.data());
        print("Teacher data fetched successfully: ${_teacherData!.teacherName}");
      } else {
        print("No teacher data found for the logged-in user.");
      }
    } catch (error) {
      print("Error fetching teacher data: $error");
    }

    _isLoading = false;
    notifyListeners();
  }
}
