import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:videosdk_flutter_example/screens/TeacherScreen.dart';
import '../screens/Navbar.dart';

class SplashProvider with ChangeNotifier {

  Future<void> navigateToNextScreen(BuildContext context) async {
    await Future.delayed(Duration(seconds: 3));


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeacherScreen()),
      );

  }
}
