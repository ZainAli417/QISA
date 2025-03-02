import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';
import 'package:videosdk_flutter_example/widgets/conference-call/manage_grid.dart';
import 'package:videosdk_flutter_example/widgets/conference-call/participant_grid_tile.dart';

class ConferenceParticipantGrid extends StatefulWidget {
  final Room meeting;
  const ConferenceParticipantGrid({Key? key, required this.meeting})
      : super(key: key);

  @override
  State<ConferenceParticipantGrid> createState() =>
      _ConferenceParticipantGridState();
}

class _ConferenceParticipantGridState extends State<ConferenceParticipantGrid> {
  late Participant localParticipant;
  String? activeSpeakerId;
  String? presenterId;
  Map<String, Participant> participants = {};
  Map<int, List<Participant>> onScreenParticipants = {};
  Map<String, int>? gridInfo;
  bool isPresenting = false;
  Map<int, List<Participant>>? activeSpeakerList;

  @override
  void initState() {
    super.initState();
    localParticipant = widget.meeting.localParticipant;
    participants.putIfAbsent(localParticipant.id, () => localParticipant);
    participants.addAll(widget.meeting.participants);
    presenterId = widget.meeting.activePresenterId;
    isPresenting = presenterId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateOnScreenParticipants();
      setMeetingListeners(widget.meeting);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveValue<Widget>(
      context,
      defaultValue: _buildHorizontalScrollView(),
      conditionalValues: [
        Condition.equals(
          name: MOBILE,
          value: participants.length <= 2 && !isPresenting
              ? _buildHorizontalScrollView()
              : _buildGridView(),
        ),
        Condition.largerThan(
          name: MOBILE,
          value: isPresenting ? _buildHorizontalScrollView() : _buildGridView(),
        ),
      ],
    ).value!;
  }

  // Horizontal Scroll View for fewer participants or presenting mode
  Widget _buildHorizontalScrollView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < onScreenParticipants.length; i++)
            for (int j = 0; j < onScreenParticipants[i]!.length; j++)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox(
                  width: 200,
                  height: 150,
                  child: ParticipantGridTile(
                    key: Key(onScreenParticipants[i]![j].id),
                    participant: onScreenParticipants[i]![j],
                    activeSpeakerId: activeSpeakerId,
                    quality: "high", // Hardcoded since no video
                    participantCount: participants.length,
                    isPresenting: isPresenting,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // Grid View for more participants
  Widget _buildGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveValue<int>(context, conditionalValues: [
          Condition.equals(name: MOBILE, value: 2),
          Condition.equals(name: TABLET, value: 3),
          Condition.largerThan(name: TABLET, value: 4),
        ]).value!,
        childAspectRatio: 4 / 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: onScreenParticipants.values
          .expand((participants) => participants)
          .length,
      itemBuilder: (context, index) {
        final participantList =
        onScreenParticipants.values.expand((p) => p).toList();
        return ParticipantGridTile(
          key: Key(participantList[index].id),
          participant: participantList[index],
          activeSpeakerId: activeSpeakerId,
          quality: "high", // Hardcoded since no video
          participantCount: participants.length,
          isPresenting: isPresenting,
        );
      },
    );
  }

  void setMeetingListeners(Room _meeting) {
    _meeting.on(Events.participantJoined, (Participant participant) {
      participants[participant.id] = participant;
      setState(() => updateOnScreenParticipants());
    });

    _meeting.on(Events.participantLeft, (participantId) {
      participants.remove(participantId);
      setState(() => updateOnScreenParticipants());
    });

    _meeting.on(Events.speakerChanged, (_activeSpeakerId) {
      try {
        setState(() {
          activeSpeakerId = _activeSpeakerId;
          updateOnScreenParticipants();
        });
      } catch (e) {}
    });

    _meeting.on(Events.presenterChanged, (presenterId) {
      setState(() {
        this.presenterId = presenterId;
        isPresenting = presenterId != null;
        updateOnScreenParticipants();
      });
    });

    // Removed streamEnabled/streamDisabled for video since camera is not used
    _meeting.localParticipant.on(Events.streamEnabled, (Stream stream) {
      if (stream.kind == "share") {
        setState(() {
          isPresenting = true;
          updateOnScreenParticipants();
        });
      }
    });

    _meeting.localParticipant.on(Events.streamDisabled, (Stream stream) {
      if (stream.kind == "share") {
        setState(() {
          isPresenting = false;
          updateOnScreenParticipants();
        });
      }
    });
  }

  void updateOnScreenParticipants() {
    gridInfo = ManageGrid.getGridRowsAndColumns(
      participantsCount: participants.length,
      device: ResponsiveValue<device_type>(context, conditionalValues: [
        Condition.equals(name: MOBILE, value: device_type.mobile),
        Condition.equals(name: TABLET, value: device_type.tablet),
        Condition.largerThan(name: TABLET, value: device_type.desktop),
      ]).value!,
      isPresenting: isPresenting,
    );

    Map<int, List<Participant>> newParticipants =
    ManageGrid.getGridForMainParticipants(
        participants: participants, gridInfo: gridInfo);

    List<Participant> participantList = [];
    if (activeSpeakerList == null) {
      newParticipants.values.forEach((element) {
        participantList.addAll(element);
      });
    } else {
      activeSpeakerList!.values.forEach((element) {
        participantList.addAll(element);
      });
    }

    int maxNoOfParticipant = isPresenting ? 2 : 6;

    if (participants.length > maxNoOfParticipant &&
        activeSpeakerId != null &&
        widget.meeting.localParticipant.id != activeSpeakerId &&
        !participantList.contains(widget.meeting.participants[activeSpeakerId])) {
      newParticipants.values.last
          .removeAt(newParticipants.values.last.length - 1);
      newParticipants.values.last.add(
          participants.values.firstWhere((p) => p.id == activeSpeakerId));
      activeSpeakerList = newParticipants;
    }

    activeSpeakerList ??= newParticipants;

    if (activeSpeakerList!.values.expand((p) => p).length !=
        newParticipants.values.expand((p) => p).length) {
      activeSpeakerList = newParticipants;
    }

    if (!listEquals(activeSpeakerList!.values.toList(),
        onScreenParticipants.values.toList())) {
      setState(() {
        onScreenParticipants = activeSpeakerList!;
      });
    }
  }
}