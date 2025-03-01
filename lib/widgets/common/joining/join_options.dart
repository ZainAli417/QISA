import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import 'package:videosdk_flutter_example/widgets/common/joining_details/joining_details.dart';
import '../../../providers/role_provider.dart';

class JoinOptions extends StatelessWidget {
  final double maxWidth;
  final Function(String meetingId, String callType, String displayName)
  onClickMeetingJoin;
  const JoinOptions({
    Key? key,
    required this.maxWidth,
    required this.onClickMeetingJoin,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(
      builder: (context, roleProvider, child) {
        // If the user is principal, treat as coordinator (create meeting)
        final bool isCoordinator = roleProvider.isPrincipal;
        return JoiningDetails(
          isCreateMeeting: isCoordinator,
          onClickMeetingJoin: onClickMeetingJoin,
        );
      },
    );
  }
}
