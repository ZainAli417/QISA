import 'package:flutter/material.dart';

class MeetingState with ChangeNotifier {
  DateTime? _joinTime;
  DateTime? _endTime;

  DateTime? get joinTime => _joinTime;
  DateTime? get endTime => _endTime;

  void setJoinTime(DateTime time) {
    _joinTime = time;
    notifyListeners();
  }

  void setEndTime(DateTime time) {
    _endTime = time;
    notifyListeners();
  }
}
