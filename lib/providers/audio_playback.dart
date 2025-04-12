import 'package:flutter/material.dart';

class AudioPlaybackProvider with ChangeNotifier {
  String? _currentAudioUrl;

  String? get currentAudioUrl => _currentAudioUrl;

  void setCurrentAudio(String url) {
    _currentAudioUrl = url;
    notifyListeners();
  }

  void clearCurrentAudio() {
    _currentAudioUrl = null;
    notifyListeners();
  }
}
