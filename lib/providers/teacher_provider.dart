import 'package:flutter/material.dart';

class TeacherProvider with ChangeNotifier {
  String teacherName = "QC";
  String avatarUrl = "assets/avatar.png"; // Local image path
  bool hasMeetingRoom = true;
}
