import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class PrincipalProvider with ChangeNotifier {
  String principalName = "";
  bool isLoading = true;
  List<Map<String, dynamic>> teacherCards = []; // List to hold all teacher data

  PrincipalProvider() {
    _fetchPrincipalName();
    _listenToStudyMaterialChanges();
  }

  Future<void> _fetchPrincipalName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot principalDoc = await FirebaseFirestore.instance
            .collection('principal')
            .doc(user.uid)
            .get();

        if (principalDoc.exists) {
          principalName =
          "${principalDoc['FirstName']} ${principalDoc['LastName']}";
        } else {
          principalName = "Principal document not found";
        }
      } else {
        principalName = "User not logged in";
      }
    } catch (e) {
      principalName = "Error fetching name";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _listenToStudyMaterialChanges() {
    FirebaseFirestore.instance
        .collection('Study_material')
        .snapshots()
        .listen((snapshot) async {
      List<Map<String, dynamic>> updatedCards = [];

      for (var doc in snapshot.docs) {
        String teacherId = doc['TeacherId'];
        DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
            .collection('teacher')
            .doc(teacherId)
            .get();

        String teacherName = teacherDoc.exists
            ? "${teacherDoc['FirstName']} ${teacherDoc['LastName']}"
            : 'Unknown Teacher';

        updatedCards.add({
          'docId': doc.id,
          'teacherName': teacherName,
          'topicName': doc['TopicName'] ?? 'No Name',
          'topicDescription': doc['TopicDescription'] ?? 'No Description',
          'audioFiles': List<String>.from(doc['AudioFiles'] ?? []),
          'status': doc['Status'] ?? 'In Review',
        });
      }

      teacherCards = updatedCards;
      _filterApprovedCards(); // Update the filtered list
      notifyListeners();
    });
  }

  void _filterApprovedCards() {
     teacherCards;
  }

  Future<void> updateStudyMaterialStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Study_material')
          .doc(docId)
          .update({'Status': status});
    } catch (e) {
      print("Error updating status: $e");
    }
  }
}
