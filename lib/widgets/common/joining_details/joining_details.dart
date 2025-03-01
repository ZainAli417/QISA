import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';

final GlobalKey<_JoiningDetailsState> assingedtokey =
GlobalKey<_JoiningDetailsState>();

class JoiningDetails extends StatefulWidget {
  final bool isCreateMeeting;
  final Function onClickMeetingJoin;

  const JoiningDetails({
    Key? key,
    required this.isCreateMeeting,
    required this.onClickMeetingJoin,
  }) : super(key: key);

  @override
  State<JoiningDetails> createState() => _JoiningDetailsState();
}

class _JoiningDetailsState extends State<JoiningDetails> {
  String _meetingId = "";
  String _displayName = "";
  String meetingMode = "GROUP";
  List<String> meetingModes = ["ONE_TO_ONE", "GROUP"];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        const VerticalSpacer(
          20,
        ), // Increased vertical spacer for better spacing
        if (!widget.isCreateMeeting)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ), // Added horizontal padding
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // More rounded corners
                color: black750,
              ),
              child: TextField(
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                onChanged: ((value) => _meetingId = value),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ), // Increased vertical padding inside textfield
                  prefixIcon: const Icon(
                    Icons.meeting_room_outlined,
                    color: textGray,
                  ), // Added icon
                  labelText: "Meeting Code", // Added label text
                  labelStyle: const TextStyle(
                    color: textGray,
                  ), // Style for label
                  floatingLabelStyle: const TextStyle(
                    color: Colors.white,
                  ), // Style for floating label when focused
                  floatingLabelBehavior:
                  FloatingLabelBehavior
                      .always, // Ensure label is always visible

                  constraints: BoxConstraints.tightFor(
                    width:
                    ResponsiveValue<double>(
                      context,
                      conditionalValues: [
                        Condition.equals(
                          name: MOBILE,
                          value: maxWidth / 1.3,
                        ),
                        Condition.equals(
                          name: TABLET,
                          value: maxWidth / 1.3,
                        ),
                        Condition.equals(
                          name: DESKTOP,
                          value: maxWidth / 3,
                        ),
                      ],
                    ).value!,
                  ),
                  hintText: "Enter meeting code here",
                  hintStyle: const TextStyle(color: textGray),
                  border: OutlineInputBorder(
                    // Use OutlineInputBorder for cleaner look
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none, // Remove default border
                  ),
                  focusedBorder: OutlineInputBorder(
                    // Border when focused
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        if (!widget.isCreateMeeting)
          const VerticalSpacer(20), // Increased vertical spacer
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ), // Added horizontal padding
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // More rounded corners
                color: black750,
              ),
              child: TextField(
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                onChanged: ((value) => _displayName = value),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ), // Increased vertical padding inside textfield
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.white70,
                  ), // Added icon
                  labelText: "Your Name", // Added label text
                  labelStyle: const TextStyle(
                    color: textGray,
                  ), // Style for label
                  floatingLabelStyle: const TextStyle(
                    color: Colors.white,
                  ), // Style for floating label when focused
                  floatingLabelBehavior:
                  FloatingLabelBehavior
                      .always, // Ensure label is always visible

                  constraints: BoxConstraints.tightFor(
                    width:
                    ResponsiveValue<double>(
                      context,
                      conditionalValues: [
                        Condition.equals(
                          name: MOBILE,
                          value: maxWidth / 1.3,
                        ),
                        Condition.equals(
                          name: TABLET,
                          value: maxWidth / 1.3,
                        ),
                        Condition.equals(
                          name: DESKTOP,
                          value: maxWidth / 3,
                        ),
                      ],
                    ).value!,
                  ),
                  hintText: "Enter your name here",
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    // Use OutlineInputBorder for cleaner look
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none, // Remove default border
                  ),
                  focusedBorder: OutlineInputBorder(
                    // Border when focused
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ),
        const VerticalSpacer(25), // Increased vertical spacer before button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ), // Horizontal padding for button
          child: MaterialButton(

            minWidth:
            ResponsiveValue<double>(
              context,
              conditionalValues: [
                Condition.equals(name: MOBILE, value: maxWidth / 1.9),
                Condition.equals(name: TABLET, value: maxWidth / 1.3),
                Condition.equals(name: DESKTOP, value: maxWidth / 3),
              ],
            ).value!,
            height: 50, // Increased button height
            elevation: 3, // Added elevation for button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ), // More rounded button
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.blue,
            child: const Text(
              "Join Meeting +",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ), // Bold font weight
            onPressed: () {
              if (_displayName.trim().isEmpty) {
                showSnackBarMessage(
                  message: "Please enter name",
                  context: context,
                );
                return;
              }
              if (!widget.isCreateMeeting && _meetingId.trim().isEmpty) {
                showSnackBarMessage(
                  message: "Please enter meeting id",
                  context: context,
                );
                return;
              }
              widget.onClickMeetingJoin(
                _meetingId.trim(),
                meetingMode,
                _displayName.trim(),
              );
            },
          ),
        ),
        const VerticalSpacer(20), // Added vertical spacer at the bottom
      ],
    );
  }
}
