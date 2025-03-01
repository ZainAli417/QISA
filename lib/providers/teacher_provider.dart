import 'package:flutter/material.dart';

class TeacherProvider with ChangeNotifier {
  String teacherName = "Zain Ali";
  String avatarUrl = "assets/avatar.png"; // Local image path
  bool hasMeetingRoom = true;
}
