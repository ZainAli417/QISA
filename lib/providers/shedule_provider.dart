import 'package:flutter/material.dart';

class ScheduleProvider extends ChangeNotifier {
  int _selectedDayIndex = 0;

  int get selectedDayIndex => _selectedDayIndex;

  void setSelectedDayIndex(int index) {
    _selectedDayIndex = index;
    notifyListeners();
  }
  List<Map<String, String>> getScheduleForSelectedDay() {
    List<List<Map<String, String>>> schedule = [
      // Monday
      [
        {"time": "11:00 AM - 12:00 AM", "subject": "Account", "class": "9 - A (Science)", "icon": "assets/images/bio.svg"},
        {"time": "12:00 AM - 01:00 PM", "subject": "Computer (Practical)", "class": "9 - A (Computer)", "icon": "assets/images/computer.svg"},
      ],
      // Tuesday
      [
        {"time": "11:00 AM - 2:00 PM", "subject": "Biology", "class": "10 - A (Science)", "icon": "assets/images/bio.svg"},

      ],
      // Wednesday
      [],
      // Thursday
      [],
      // Friday
      [],
      // Saturday
      [],
      // Sunday
      [],
    ];

    return schedule[_selectedDayIndex];
  }

}
