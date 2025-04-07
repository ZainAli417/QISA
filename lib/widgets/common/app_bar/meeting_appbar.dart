import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';
import 'package:videosdk_flutter_example/screens/TeacherScreen.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';
import 'package:videosdk_flutter_example/widgets/common/app_bar/recording_indicator.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import '../../../constants/Common_appbar.dart';
import '../../../providers/role_provider.dart';

class MeetingAppBar extends StatefulWidget {
  final String token;
  final Room meeting;
  final String recordingState;
  final bool isFullScreen;

  const MeetingAppBar({
    Key? key,
    required this.meeting,
    required this.token,
    required this.isFullScreen,
    required this.recordingState,
  }) : super(key: key);

  @override
  State<MeetingAppBar> createState() => MeetingAppBarState();
}

class MeetingAppBarState extends State<MeetingAppBar>
    with MeetingAppBarLogic<MeetingAppBar> {
  List<VideoDeviceInfo>? cameras = [];

  @override
  void initState() {
    super.initState();
    fetchTeachers(widget.meeting.id); // Fetch teachers asynchronously
    fetchVideoDevices();
    // Auto-trigger savedata only if the user is a principal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSaveInitialData();
    });
  }

  void fetchVideoDevices() async {
    cameras = await VideoSDK.getVideoDevices();
    setState(() {});
  }

  // Handle initial auto-save only for principal
  void _autoSaveInitialData() {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    if (!roleProvider.isPrincipal) return; // Only proceed if principal

    // Use the first teacher if list is populated; otherwise, save with null (Unassigned in savedata)
    final initialTeacher = teacherList.isNotEmpty ? teacherList[0] : null;
    if (teacherList.isNotEmpty) {
      setState(() {
        selectedTeacher = initialTeacher; // Set the selected teacher if available
      });
    }
    savedata(initialTeacher, widget.meeting.id); // Save the data (null if no teachers available)
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: !widget.isFullScreen
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      secondChild: const SizedBox.shrink(),
      firstChild: Padding(
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
              const HorizontalSpacer(),
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
                          child: Icon(Icons.copy,
                              size: 16, color: Colors.white),
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
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
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
                            if (newValue != null) {
                              setState(() {
                                selectedTeacher = newValue;
                              });
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
          ],
        ),
      ),
    );
  }
}
