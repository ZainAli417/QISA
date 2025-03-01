import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';
import 'package:videosdk_flutter_example/widgets/common/app_bar/recording_indicator.dart';
import '../../../constants/Common_appbar.dart';
import '../../../providers/role_provider.dart';
import '../../../screens/SplashScreen.dart';
import '../../../screens/TeacherScreen.dart';

class WebMeetingAppBar extends StatefulWidget {
  final String token;
  final Room meeting;
  final bool isMicEnabled,
      isCamEnabled,
      isLocalScreenShareEnabled,
      isRemoteScreenShareEnabled;
  final String recordingState;

  const WebMeetingAppBar({
    Key? key,
    required this.meeting,
    required this.token,
    required this.recordingState,
    required this.isMicEnabled,
    required this.isCamEnabled,
    required this.isLocalScreenShareEnabled,
    required this.isRemoteScreenShareEnabled,
  }) : super(key: key);

  @override
  State<WebMeetingAppBar> createState() => WebMeetingAppBarState();
}

class WebMeetingAppBarState extends State<WebMeetingAppBar>
    with MeetingAppBarLogic<WebMeetingAppBar> {
  List<AudioDeviceInfo>? mics;
  List<AudioDeviceInfo>? speakers;
  List<VideoDeviceInfo>? cameras;

  @override
  void initState() {
    super.initState();
    // Start the timer and fetch shared data.
  //  startTimer(widget.token, widget.meeting.id);
    fetchVideoDevices();
    fetchAudioDevices();
    fetchTeachers(widget.meeting.id);
  }

  void fetchVideoDevices() async {
    cameras = await VideoSDK.getVideoDevices();
    setState(() {});
  }

  void fetchAudioDevices() async {
    List<AudioDeviceInfo>? audioDevices = await VideoSDK.getAudioDevices();
    mics = [];
    speakers = [];
    if (audioDevices != null) {
      for (AudioDeviceInfo device in audioDevices) {
        if (device.kind == 'audiooutput') {
          speakers?.add(device);
        } else {
          mics?.add(device);
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 8.0, 0.0),
      child: Row(
        children: [
          // Back button.
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final roleProvider =
              Provider.of<RoleProvider>(context, listen: false);
              Navigator.pop(context);
              widget.meeting.leave();

              // Navigate based on role.
              if (roleProvider.isPrincipal) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherScreen()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              }
            },
          ),
          if (widget.recordingState == "RECORDING_STARTING" ||
              widget.recordingState == "RECORDING_STOPPING" ||
              widget.recordingState == "RECORDING_STARTED")
            RecordingIndicator(recordingState: widget.recordingState),
          if (widget.recordingState == "RECORDING_STARTING" ||
              widget.recordingState == "RECORDING_STOPPING" ||
              widget.recordingState == "RECORDING_STARTED")
            const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.meeting.id,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                        child: Icon(Icons.copy, size: 16, color: Colors.white),
                      ),
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.meeting.id));
                        showSnackBarMessage(
                            message: "Meeting ID has been copied.",
                            context: context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // If the user is principal, show the teacher dropdown.
          Consumer<RoleProvider>(
            builder: (context, roleProvider, child) {
              if (roleProvider.isPrincipal) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedTeacher,
                        hint: Text(
                          "Assign Meeting",
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                        dropdownColor: Colors.black87,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            const BorderSide(color: Colors.white70),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        items: teacherList.map((String teacher) {
                          return DropdownMenuItem<String>(
                            value: teacher,
                            child: Text(teacher),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTeacher = newValue;
                          });
                          if (newValue != null) {
                            savedata(newValue, widget.meeting.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          // Switch camera button.
          IconButton(
            icon: SvgPicture.asset(
              "assets/ic_switch_camera.svg",
              height: 24,
              width: 24,
            ),
            onPressed: () {
              VideoDeviceInfo? newCam = cameras?.firstWhere(
                      (camera) =>
                  camera.deviceId != widget.meeting.selectedCam?.deviceId);
              if (newCam != null) {
                widget.meeting.changeCam(newCam);
              }
            },
          ),
        ],
      ),
    );
  }
}
