import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';

class JoinView extends StatelessWidget {
  final RTCVideoRenderer? cameraRenderer;
  final bool isMicOn;
  final bool isCameraOn;
  final VoidCallback onMicToggle;
  final VoidCallback onCameraToggle;

  const JoinView({
    Key? key,
    required this.cameraRenderer,
    required this.isMicOn,
    required this.isCameraOn,
    required this.onMicToggle,
    required this.onCameraToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row();


  }
}