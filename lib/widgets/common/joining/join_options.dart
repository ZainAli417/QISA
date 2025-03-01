import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import 'package:videosdk_flutter_example/widgets/common/joining_details/joining_details.dart';

import '../../../providers/role_provider.dart';

class JoinOptions extends StatelessWidget {
  final bool? isJoinMeetingSelected;
  final bool? isCreateMeetingSelected;
  final double maxWidth;
  final Function(bool isCreateMeeting) onOptionSelected;
  final Function(String meetingId, String callType, String displayName)
      onClickMeetingJoin;

  const JoinOptions({
    Key? key,
    required this.isJoinMeetingSelected,
    required this.isCreateMeetingSelected,
    required this.maxWidth,
    required this.onOptionSelected,
    required this.onClickMeetingJoin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isJoinMeetingSelected == null && isCreateMeetingSelected == null)
    Consumer<RoleProvider>(
        builder: (context, roleProvider, child) {
      if (roleProvider.isPrincipal) {
        return  MaterialButton(
            minWidth: ResponsiveValue<double>(context, conditionalValues: [
              Condition.equals(name: MOBILE, value: maxWidth / 1.3),
              Condition.equals(name: TABLET, value: maxWidth / 1.3),
              Condition.equals(name: DESKTOP, value: maxWidth / 3 ),
            ]).value!,
            height: ResponsiveValue<double>(context, conditionalValues: [
              Condition.equals(name: MOBILE, value: 50),
              Condition.equals(name: TABLET, value: 50),
              Condition.equals(name: DESKTOP, value: 55),
            ]).value!,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: purple,

            child: const Text("Coordinator? Create Meeting", style: TextStyle(fontSize: 16, color: Colors.white)),

            onPressed: () => onOptionSelected(true),
          );
          } else {
          // Return an empty container if the conditions are not met
          return SizedBox.shrink();
          }
        },
    ),
        const VerticalSpacer(16),
        if (isJoinMeetingSelected == null && isCreateMeetingSelected == null)
          MaterialButton(
            minWidth: ResponsiveValue<double>(context, conditionalValues: [
              Condition.equals(name: MOBILE, value: maxWidth / 1.3),
              Condition.equals(name: TABLET, value: maxWidth / 1.3),
              Condition.equals(name: DESKTOP, value: maxWidth / 3 ),
            ]).value!,
            height: ResponsiveValue<double>(context, conditionalValues: [
              Condition.equals(name: MOBILE, value: 50),
              Condition.equals(name: TABLET, value: 50),
              Condition.equals(name: DESKTOP, value: 55),
            ]).value!,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white10,
            child: const Text("Have A Meeting Code Proceed to Join Meeting", style: TextStyle(fontSize: 14, color: Colors.white)),
            onPressed: () => onOptionSelected(false),
          ),
        if (isJoinMeetingSelected != null && isCreateMeetingSelected != null)
          JoiningDetails(
            isCreateMeeting: isCreateMeetingSelected!,
            onClickMeetingJoin: onClickMeetingJoin,
          ),
      ],
    );
  }
}