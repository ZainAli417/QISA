import 'package:flutter/material.dart';

class RoleProvider with ChangeNotifier {
  bool isStudent = false;
  bool isTeacher = false;
  bool isPrincipal = false;
  bool isParents = false;

  void setRole(String role) {
    // Reset all roles to false first
    isStudent = false;
    isTeacher = false;
    isPrincipal = false;
    isParents = false;

    // Set the selected role to true
    if (role == 'Student') {
      isStudent = true;
    } else if (role == 'Teacher') {
      isTeacher = true;
    } else if (role == 'Principal') {
      isPrincipal = true;
    }else if (role == 'Parents') {
      isParents = true;
    }

    notifyListeners();
  }
}
