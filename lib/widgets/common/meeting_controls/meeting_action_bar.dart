import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:touch_ripple_effect/touch_ripple_effect.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';
import 'package:videosdk_flutter_example/screens/TeacherScreen.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import '../../../constants/colors.dart';
import '../../../providers/role_provider.dart';

// Meeting ActionBar
class MeetingActionBar extends StatelessWidget {
  final Room meeting;
  final bool isMicEnabled, isCamEnabled, isScreenShareEnabled;
  final String recordingState;

  // callback functions
  final void Function() onCallEndButtonPressed,
      onCallLeaveButtonPressed,
      onMicButtonPressed,
      onCameraButtonPressed,
      onChatButtonPressed;
  final void Function(String) onMoreOptionSelected;
  final void Function(TapDownDetails) onSwitchMicButtonPressed;

  const MeetingActionBar({
    Key? key,
    required this.meeting,
    required this.isMicEnabled,
    required this.isCamEnabled,
    required this.isScreenShareEnabled,
    required this.recordingState,
    required this.onCallEndButtonPressed,
    required this.onCallLeaveButtonPressed,
    required this.onMicButtonPressed,
    required this.onSwitchMicButtonPressed,
    required this.onCameraButtonPressed,
    required this.onMoreOptionSelected,
    required this.onChatButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final participantId = meeting.localParticipant.id;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Teacher/Principal Leave/End Button
          Consumer<RoleProvider>(
            builder: (context, roleProvider, child) {
              if (roleProvider.isTeacher || roleProvider.isPrincipal) {
                return PopupMenuButton(
                  position: PopupMenuPosition.under,
                  padding: const EdgeInsets.all(0),
                  color: Colors.black54,
                  icon: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                      color: Colors.red,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.call_end,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  offset: const Offset(0, -185),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    // Update inmeeting status to false for this participant
                    try {
                      await FirebaseFirestore.instance
                          .collection('meeting_record')
                          .doc(meeting.id)
                          .collection('Stats')
                          .doc(participantId) // Use the participant ID of the teacher/principal
                          .update({'inmeeting': false});
                    } catch (e) {
                      print("Error updating inmeeting status: $e");
                    }

                    if (value == "leave") {
                      onCallLeaveButtonPressed();
                    } else if (value == "end") {
                      onCallEndButtonPressed();
                    }

                    // Navigate based on role after leaving or ending
                    if (roleProvider.isTeacher) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SplashScreen()),
                      );
                    } else if (roleProvider.isPrincipal) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => TeacherScreen()),
                      );
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry>[
                    _buildMeetingPoupItem(
                      "leave",
                      "Leave",
                      "Only you will leave the call",
                      SvgPicture.asset("assets/ic_leave.svg"),
                    ),
                    const PopupMenuDivider(),
                    _buildMeetingPoupItem(
                      "end",
                      "End",
                      "End call for all participants",
                      SvgPicture.asset("assets/ic_end.svg"),
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          // Student Leave Button
          Consumer<RoleProvider>(
            builder: (context, roleProvider, child) {
              if (roleProvider.isStudent ) {
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                  ),
                  icon: const Icon(
                    Icons.call_end,
                    size: 30,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Leave Meeting",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('meeting_record')
                          .doc(meeting.id)
                          .collection('Stats')
                          .doc(participantId)
                          .update({'inmeeting': false});
                    } catch (e) {
                      print("Error updating inmeeting status: $e");
                    }
                    onCallLeaveButtonPressed();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          // Mic Control
          TouchRippleEffect(
            borderRadius: BorderRadius.circular(12),
            rippleColor: isMicEnabled ? primaryColor : Colors.white,
            onTap: onMicButtonPressed,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: secondaryColor),
                color: isMicEnabled ? primaryColor : Colors.white,
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    isMicEnabled ? Icons.mic : Icons.mic_off,
                    size: 30,
                    color: isMicEnabled ? Colors.white : primaryColor,
                  ),
                  GestureDetector(
                    onTapDown: onSwitchMicButtonPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: isMicEnabled ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // More Options (for Teacher/Principal)
          Consumer<RoleProvider>(
            builder: (context, roleProvider, child) {
              if (roleProvider.isTeacher || roleProvider.isPrincipal) {
                return PopupMenuButton(
                  position: PopupMenuPosition.under,
                  padding: const EdgeInsets.all(0),
                  color: black700,
                  icon: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: secondaryColor),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.more_vert,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  offset: const Offset(0, -250),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) =>
                  {onMoreOptionSelected(value.toString())},
                  itemBuilder: (context) => <PopupMenuEntry>[
                    _buildMeetingPoupItem(
                      "recording",
                      recordingState == "RECORDING_STARTED"
                          ? "Stop Recording"
                          : recordingState == "RECORDING_STARTING"
                          ? "Recording is starting"
                          : "Start Recording",
                      null,
                      SvgPicture.asset("assets/ic_recording.svg"),
                    ),
                    const PopupMenuDivider(),
                    _buildMeetingPoupItem(
                      "screenshare",
                      isScreenShareEnabled
                          ? "Stop Screen Share"
                          : "Start Screen Share",
                      null,
                      SvgPicture.asset("assets/ic_screen_share.svg"),
                    ),
                    const PopupMenuDivider(),
                    _buildMeetingPoupItem(
                      "participants",
                      "Participants",
                      null,
                      SvgPicture.asset("assets/ic_participants.svg"),
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  PopupMenuItem<dynamic> _buildMeetingPoupItem(
      String value, String title, String? description, Widget leadingIcon) {
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
      child: Row(
        children: [
          leadingIcon,
          const HorizontalSpacer(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
              if (description != null) const VerticalSpacer(4),
              if (description != null)
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: black400),
                )
            ],
          )
        ],
      ),
    );
  }
}
