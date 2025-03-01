import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:touch_ripple_effect/touch_ripple_effect.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/utils/api.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';
import 'package:videosdk_flutter_example/widgets/common/app_bar/recording_indicator.dart';
import 'package:videosdk_flutter_example/widgets/common/chat/chat_view.dart';
import 'package:videosdk_flutter_example/widgets/common/participant/participant_list.dart';
import 'package:videosdk_webrtc/flutter_webrtc.dart';
import 'package:videosdk_flutter_example/widgets/common/screen_share/screen_select_dialog.dart';

import '../../../providers/role_provider.dart';
import '../../../screens/SplashScreen.dart';
import '../../../screens/TeacherScreen.dart';
import '../../../screens/common/join_screen.dart';

class WebMeetingAppBar extends StatefulWidget {
  final String token;
  final Room meeting;
  // control states
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

class WebMeetingAppBarState extends State<WebMeetingAppBar> {
  Duration? elapsedTime;
  Timer? sessionTimer;
  List<AudioDeviceInfo>? mics;
  List<AudioDeviceInfo>? speakers;
  List<VideoDeviceInfo>? cameras;
  String? selectedTeacher;
  List<String> teacherList = [];

  @override
  void initState() {
    startTimer();
    fetchVideoDevices();
    fetchAudioDevices();
    super.initState();
    fetchTeachers();
  }

  void fetchTeachers() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('room_metadata')
          .doc('i5NpyLzF5fE1zKyPa9r1') // Correct document path
          .get();

      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data.containsKey('teacher_list')) {
          // teacher_list is a field
          List<dynamic> fetchedTeachers = data['teacher_list'];
          setState(() {
            teacherList = List<String>.from(fetchedTeachers);
          });
        }
      }
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 8.0, 0.0),
      child: Row(
        children: [
          // Go Back Arrow
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              // Get the RoleProvider instance
              final roleProvider =
                  Provider.of<RoleProvider>(context, listen: false);

              // Pop the current screen and call meeting.leave() method
              Navigator.pop(context);
              widget.meeting.leave(); // Call meeting.leave() method

              // Check the role and navigate to the appropriate screen
              if (roleProvider.isPrincipal) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TeacherScreen()), // Navigate to TeacherScreen
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SplashScreen()), // Navigate to SplashScreen
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
            const HorizontalSpacer(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.meeting.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white,
                        ),
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
                /*Text(
                    elapsedTime == null
                        ? "00:00:00"
                        : elapsedTime.toString().split(".").first,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  )*/
              ],
            ),
          ),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        dropdownColor: Colors.black87,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white70),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
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
                            savedata(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // Return an empty container if the conditions are not met
                return SizedBox.shrink();
              }
            },
          ),
          IconButton(
            icon: SvgPicture.asset(
              "assets/ic_switch_camera.svg",
              height: 24,
              width: 24,
            ),
            onPressed: () {
              VideoDeviceInfo? newCam = cameras?.firstWhere((camera) =>
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

  void savedata(String teacher) async {
    try {
      // Add a new document with auto-generated ID
      await FirebaseFirestore.instance.collection('meeting_record').add({
        'assigned_to': teacher,
        'room_id': widget.meeting.id,
        'room_name': 'Zain Ali',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting assigned to $selectedTeacher')),
      );
    } catch (e) {
      print('Error assigning meeting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign meeting')),
      );
    }
  }

  Future<void> startTimer() async {
    dynamic session = await fetchSession(widget.token, widget.meeting.id);
    DateTime sessionStartTime = DateTime.parse(session['start']);
    final difference = DateTime.now().difference(sessionStartTime);

    setState(() {
      elapsedTime = difference;
      sessionTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          setState(() {
            elapsedTime = Duration(
                seconds: elapsedTime != null ? elapsedTime!.inSeconds + 1 : 0);
          });
        },
      );
    });
    // log("session start time" + session.data[0].start.toString());
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

  Future<DesktopCapturerSource?> selectScreenSourceDialog(
      BuildContext context) async {
    final source = await showDialog<DesktopCapturerSource>(
      context: context,
      builder: (context) => ScreenSelectDialog(
        meeting: widget.meeting,
      ),
    );
    return source;
  }

  PopupMenuItem<dynamic> _buildMeetingPoupItem(
      dynamic value, String title, String? description,
      {Widget? leadingIcon, Color? textColor, bool isSelected = false}) {
    return PopupMenuItem(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        color: isSelected
            ? Color.fromRGBO(109, 110, 113, 1)
            : Colors.transparent, // Set the selected color
        padding: const EdgeInsets.symmetric(
            vertical: 8), // Only vertical padding to avoid side spaces
        margin: EdgeInsets.zero, // Remove margin to avoid spaces on sides
        child: Row(
          children: [
            if (leadingIcon != null)
              const SizedBox(width: 16), // Manual spacing on the left
            leadingIcon ?? const Center(),
            const HorizontalSpacer(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                  if (description != null) const VerticalSpacer(4),
                  if (description != null)
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: black400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16), // Manual spacing on the right
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (sessionTimer != null) {
      sessionTimer!.cancel();
    }
    super.dispose();
  }
}
