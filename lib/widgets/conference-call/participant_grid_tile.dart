import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/widgets/common/stats/call_stats.dart';

import '../../providers/role_provider.dart';

class ParticipantGridTile extends StatefulWidget {
  final String meetingId; // meetingId to build Firestore path.
  final Participant participant;
  final bool isLocalParticipant;
  final String? activeSpeakerId;
  final String? quality;
  final int participantCount;
  final bool isPresenting;

  const ParticipantGridTile({
    Key? key,
    required this.meetingId,
    required this.participant,
    required this.quality,
    this.isLocalParticipant = false,
    required this.activeSpeakerId,
    required this.participantCount,
    required this.isPresenting,
  }) : super(key: key);

  @override
  State<ParticipantGridTile> createState() => _ParticipantGridTileState();
}

class _ParticipantGridTileState extends State<ParticipantGridTile> {
  Stream? videoStream;
  Stream? audioStream;

  @override
  void initState() {
    _initStreamListeners();
    super.initState();

    widget.participant.streams.forEach((key, Stream stream) {
      setState(() {
        if (stream.kind == 'video') {
          videoStream = stream;
          widget.participant.setQuality(widget.quality);
        } else if (stream.kind == 'audio') {
          audioStream = stream;
        }
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: ResponsiveValue<double>(
          context,
          defaultValue: double.infinity, // Fallback value when conditions don't match
          conditionalValues: [
            Condition.equals(name: MOBILE, value: double.infinity),
            Condition.largerThan(
              name: MOBILE,
              value: widget.isPresenting
                  ? double.infinity
                  : kIsWeb && widget.participantCount == 1
                  ? MediaQuery.of(context).size.width / 1.5
                  : widget.participantCount > 2
                  ? widget.participantCount >= 5
                  ? 350
                  : 500
                  : double.infinity,
            ),
          ],
        ).value!,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: black800,
        border: widget.activeSpeakerId != null &&
            widget.activeSpeakerId == widget.participant.id
            ? Border.all(color: Colors.blueAccent)
            : null,
      ),
      child: Stack(
        children: [
          // Center container: Listen to Firestore for the participant's role.
          Center(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('meeting_record')
                  .doc(widget.meetingId)
                  .collection('Stats')
                  .doc(widget.participant.id)
                  .snapshots(),
              builder: (context, snapshot) {
                String role = "";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data();
                  if (data != null && data.containsKey("role")) {
                    role = data["role"] as String;
                  }
                }
                // Determine custom styling based on role.
                Color containerColor;
                double nameFontSize;
                double roleFontSize;
                switch (role.toLowerCase()) {
                  case "student":
                    containerColor = Colors.red;
                    nameFontSize = 14;
                    roleFontSize = 16;
                    break;
                  case "teacher":
                    containerColor = Colors.blue;
                    nameFontSize = 14;
                    roleFontSize = 16;
                    break;
                  case "principal":
                    containerColor = Colors.teal;
                    nameFontSize = 14;
                    roleFontSize = 16;
                    break;
                  default:
                    containerColor = Colors.grey;
                    nameFontSize = 14;
                    roleFontSize = 16;
                }

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: containerColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (role.isNotEmpty)
                        Text(
                          role.toUpperCase(),
                          style: GoogleFonts.quicksand(
                            fontSize: roleFontSize,
                            color: Colors.white,

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      // Smaller name font.
                      Text(
                        widget.participant.displayName.toUpperCase(),
                        style: GoogleFonts.quicksand(
                          fontSize: nameFontSize,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Larger role font.

                    ],
                  ),
                );
              },
            ),
          ),
          // Show mic-off icon if no audio stream available.
          if (audioStream == null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: black700,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.mic_off,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ),
          // Participant name label at bottom left.
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.participant.isLocal
                    ? "You"
                    : widget.participant.displayName,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Call stats at top left.
          Positioned(
            top: 4,
            left: 4,
            child: CallStats(participant: widget.participant),
          ),
        ],
      ),
    );
  }

  _initStreamListeners() {
    widget.participant.on(Events.streamEnabled, (Stream _stream) {
      setState(() {
        if (_stream.kind == 'video') {
          videoStream = _stream;
          widget.participant.setQuality(widget.quality);
        } else if (_stream.kind == 'audio') {
          audioStream = _stream;
        }
      });
    });

    widget.participant.on(Events.streamDisabled, (Stream _stream) {
      setState(() {
        if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
          videoStream = null;
        } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
          audioStream = null;
        }
      });
    });

    widget.participant.on(Events.streamPaused, (Stream _stream) {
      setState(() {
        if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
          videoStream = null;
        } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
          audioStream = _stream;
        }
      });
    });

    widget.participant.on(Events.streamResumed, (Stream _stream) {
      setState(() {
        if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
          videoStream = _stream;
          widget.participant.setQuality(widget.quality);
        } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
          audioStream = _stream;
        }
      });
    });
  }
}
