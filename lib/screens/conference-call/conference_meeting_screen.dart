import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';
import 'package:videosdk_flutter_example/screens/TeacherScreen.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';
import 'package:videosdk_flutter_example/widgets/common/app_bar/meeting_appbar.dart';
import 'package:videosdk_flutter_example/widgets/common/app_bar/web_meeting_appbar.dart';
import 'package:videosdk_flutter_example/widgets/common/chat/chat_view.dart';
import 'package:videosdk_flutter_example/widgets/common/joining/waiting_to_join.dart';
import 'package:videosdk_flutter_example/widgets/common/meeting_controls/meeting_action_bar.dart';
import 'package:videosdk_flutter_example/widgets/common/participant/participant_list.dart';
import 'package:videosdk_flutter_example/widgets/conference-call/conference_participant_grid.dart';
import 'package:videosdk_flutter_example/widgets/conference-call/conference_screenshare_view.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../providers/meeting_provider.dart';
import '../../providers/principal_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/topic_provider.dart';
import '../../utils/api.dart';
import '../Quiz and Audio/Audio_Player_UI.dart';
import '../Quiz and Audio/Quiz_Widget.dart';

class ConferenceMeetingScreen extends StatefulWidget {
  final String meetingId, token, displayName;
  final bool micEnabled, camEnabled, chatEnabled;
  final AudioDeviceInfo? selectedAudioOutputDevice, selectedAudioInputDevice;
  final CustomTrack? cameraTrack;
  final CustomTrack? micTrack;

  const ConferenceMeetingScreen({
    Key? key,
    required this.meetingId,
    required this.token,
    required this.displayName,
    this.micEnabled = true,
    this.camEnabled = true,
    this.chatEnabled = true,
    this.selectedAudioOutputDevice,
    this.selectedAudioInputDevice,
    this.cameraTrack,
    this.micTrack,
  }) : super(key: key);

  @override
  State<ConferenceMeetingScreen> createState() =>
      _ConferenceMeetingScreenState();
}

class _ConferenceMeetingScreenState extends State<ConferenceMeetingScreen> {
  bool isRecordingOn = false;
  bool showChatSnackbar = true;

  String recordingState = "RECORDING_STOPPED";
  late Room meeting;
  bool _joined = false;
  Stream? shareStream;
  Stream? videoStream;
  Stream? audioStream;
  Stream? remoteParticipantShareStream;
  bool fullScreen = false;
  bool isMicEnabled = true; // assume mic starts enabled
  bool _isLoading = true;
  AudioPlayer? _currentAudioPlayer;
  String? _currentPlayingAudioUrl;
  int audioPlayedCount = 0; // Counter to track audio plays for stats
  List<Map<String, dynamic>> _broadcasts = []; // To store fetched broadcasts
  List<Map<String, dynamic>> audioFiles = []; // To store fetched broadcasts

  String? selectedTeacher;
  bool _initialized = false;

  StreamSubscription? _broadcastSubscription;

  late DatabaseReference _dbRef;
  Timer? _timer;
  int _remainingMinutes = 30;
  bool isTeacher = false;
  bool isStudent = false;
  bool isPrincipal = false;
  bool isLocalMicEnabled = false;

  @override


  void didChangeDependencies() {
    super.didChangeDependencies();

    isTeacher = context.read<RoleProvider>().isTeacher;
    isStudent = context.read<RoleProvider>().isStudent;
    isPrincipal = context.read<RoleProvider>().isPrincipal;

    if (!_initialized) {
      if (isTeacher) {
        _initializeTimer(); // Only teacher starts timer
      } else {
        _listenToRemainingTime(); // Others just listen
      }



      _initialized = true; // <- Add a boolean to prevent this from running multiple times
    }
  }
  @override
  void initState() {
    super.initState();

    isLocalMicEnabled = audioStream != null;
    getAssignedTeacherFromDB(widget.meetingId);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    meeting = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      customCameraVideoTrack: widget.cameraTrack,
      customMicrophoneAudioTrack: widget.micTrack,
      displayName: widget.displayName,
      micEnabled: widget.micEnabled,
      camEnabled: widget.camEnabled,
      maxResolution: 'hd',
      multiStream: true,
      notification: const NotificationInfo(
        title: "QISA",
        message: "Qisa is sharing screen in the meeting",
        icon: "notification_share",
      ),
    );

    registerMeetingEvents(meeting);

    meeting.join().then((_) {
      // Capture join time if teacher.
      if (context.read<RoleProvider>().isTeacher||isStudent) {
        // Set join time in MeetingState provider.
        final meetingState = Provider.of<MeetingState>(context, listen: false);
        meetingState.setJoinTime(DateTime.now());
      }
      Future.delayed(const Duration(seconds: 1));
      storeParticipantStats();
    });


    _dbRef = FirebaseDatabase.instance.ref("remainingTime/${widget.meetingId}");

    _setupAudioFilesListener();
    _setupBroadcastListener();
  }

  void _initializeTimer() async {
    final snapshot = await _dbRef.get();

    if (snapshot.exists) return; // Timer already started

    _dbRef.set(_remainingMinutes); // Set initial time in the database
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        if (_remainingMinutes > 0) {
          _remainingMinutes--;
          _dbRef.set(_remainingMinutes); // Update in real time
        }

        if (_remainingMinutes == 10) {
          _showWarningPopup();
        }

        if (_remainingMinutes == 0) {
          _timer?.cancel();
          meeting.end();

          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SplashScreen()),
            );
          });
        }
      });
    });
  }
  StreamSubscription<DatabaseEvent>? _remainingTimeSubscription;
  void _listenToRemainingTime() {
    _remainingTimeSubscription = _dbRef.onValue.listen((event) {
      final time = event.snapshot.value as int?;
      if (time != null && !isTeacher && mounted) {
        setState(() {
          _remainingMinutes = time;
        });
      }
    });
  }
  void _showWarningPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'You will be automatically disconnected in 10 minutes.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }








  void _setupBroadcastListener() {
    final collectionRef =
    FirebaseFirestore.instance.collection('broadcast_voice');

    _broadcastSubscription = collectionRef
        .orderBy('CreatedAt', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        _broadcasts = querySnapshot.docs.map((doc) {
          return {
            'audioFiles': List<String>.from(doc['AudioFiles']),
            'coordinator': doc['Coordinator'],
            'createdAt': doc['CreatedAt'], // Optional for display or sorting
          };
        }).toList();
      });
    });
  }
  StreamSubscription? _audioFilesSubscription;
  void _setupAudioFilesListener() {
    final collectionRef =
    FirebaseFirestore.instance.collection('Study_material');

    _audioFilesSubscription = collectionRef
        .orderBy('CreatedAt', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        audioFiles = querySnapshot.docs.map((doc) {
          return {
            'audioFiles': List<String>.from(doc['AudioFiles']),
            'createdAt': doc['CreatedAt'], // Optional for display or sorting
          };
        }).toList();
      });
    });
  }
  void _playAudio_broad(String audioUrl) {
    setState(() {
      // Toggle play state.
      if (_currentPlayingAudioUrl == audioUrl) {
        _currentPlayingAudioUrl = null;
      } else {
        _currentPlayingAudioUrl = audioUrl;
      }
    });
  }
  void _playAudio_stats(String audioUrl) {
    setState(() {
      if (_currentPlayingAudioUrl == audioUrl) {
        _currentPlayingAudioUrl = null;
      } else {
        _currentPlayingAudioUrl = audioUrl;
        audioPlayedCount++;
      }
    });
    print("Audio played count: $audioPlayedCount");
    try {
      updateAudioCountInFirestore(audioPlayedCount); // Your function to update Firestore.
      print("Firestore count updated successfully.");
    } catch (e) {
      print("Error updating Firestore count: $e");
    }
  }





  Future<void> updateAudioCountInFirestore(int playCount) async {
    final participantId = meeting.localParticipant.id;
    final DocumentReference participantDoc =
    FirebaseFirestore.instance.collection('meeting_record')
        .doc(meeting.id)
        .collection('Stats')
        .doc(participantId);

    await participantDoc.update({'audioPlayedCount': playCount});
    print('Updated audio played count for participant $participantId: $playCount');
  }
  Future<void> storeParticipantStats() async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    String role = roleProvider.isTeacher
        ? 'Teacher'
        : roleProvider.isStudent
        ? 'Student'
        : roleProvider.isPrincipal
        ? 'Principal'
        : 'Parents';


    final participantId = meeting.localParticipant
        .id; // Retrieve participant ID

    final data = {
      'displayName': widget.displayName,
     // 'joinTime': FieldValue.serverTimestamp(),
      // Store current time as a Timestamp
      'audioPlayedCount': 0,
      'role': role,
      // Initialize audio played count to zero
      'Q_marks': 0,
      // Initialize quiz marks
      'isLocal': true,
      // Set to true since this is the local participant
      'inmeeting': true,
      // Set to true since this is the local participant
    };

    try {
      final DocumentReference participantDoc = FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(meeting.id)
          .collection('Stats')
          .doc(participantId);

      await participantDoc.set(data, SetOptions(merge: true));
      print('Participant stats stored for participant $participantId');
    } catch (e) {
      print('Error saving participant stats: $e');
    }
  }
  Future<String> getAssignedTeacherFromDB(String meetingId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(meetingId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('assigned_to')) {
          final assignedTeacher = data['assigned_to'] as String;
          return assignedTeacher;
        }
      }
    } catch (e) {
      debugPrint("Error retrieving assigned teacher: $e");
    }
    return "";
  }




  @override
  Widget build(BuildContext context) {
    final String participantId = meeting.localParticipant.id;


    final statusbarHeight = MediaQuery.of(context).padding.top;
    bool isWebMobile = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        bool shouldPop = await _onWillPopScope();
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: _joined
          ? SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[900],
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // AppBar based on platform
              !isWebMobile &&
                  (kIsWeb || Platform.isMacOS || Platform.isWindows)
                  ? MeetingAppBar_web(
                meeting: meeting,
                token: widget.token,
                recordingState: recordingState,
                isFullScreen: fullScreen,

              )
                  : MeetingAppBar(
                meeting: meeting,
                token: widget.token,
                recordingState: recordingState,
                isFullScreen: fullScreen,
              ),
              Divider(color: Colors.grey[700], height: 1),
              // Remaining Time
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Remaining Time: $_remainingMinutes minutes',
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(color: Colors.grey[700], height: 1),

        Expanded(
          flex: 4,
                child: Container(
                  height: 500,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 8.0),

                  child: ConferenceParticipantGrid(meeting: meeting),
                ),
              ),

              // Broadcasts / Announcements
              _broadcasts.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No Announcements Made Till Now.',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _broadcasts.length,
                  itemBuilder: (context, index) {
                    final broadcast = _broadcasts[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coordinator: ${broadcast['coordinator']}',
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            if (broadcast['audioFiles'].isNotEmpty)
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: broadcast['audioFiles']
                                    .map<Widget>((audioUrl) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 5.0),
                                    child: AudioPlayerWidget(
                                      audioUrl: audioUrl,
                                      onPlay: () => _playAudio_broad(audioUrl),
                                      isPlaying: _currentPlayingAudioUrl == audioUrl,
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Conference Participants
              Divider(color: Colors.grey[700], height: 1),
// Action Buttons for Bottom Sheets
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Consumer<RoleProvider>(
                  builder: (context, roleProvider, child) {
                    List<Widget> buttons = [];

                    // Teacher: Show only "Lectures"
                    if (roleProvider.isTeacher) {
                      buttons.add(
                        _buildActionButton(
                          context: context,
                          icon: Icons.book,
                          label: 'Lectures',
                          onPressed: () => Lecture_button_Conditional_Trigger(context),
                        ),
                      );
                    }

                    // Student: Show "Lectures" + "Quiz"
                    if (roleProvider.isStudent) {
                      buttons.addAll([
                        _buildActionButton(
                          context: context,
                          icon: Icons.book,
                          label: 'Lectures',
                          onPressed: () => Lecture_button_Conditional_Trigger(context),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.quiz,
                          label: 'Quiz',
                          onPressed: () => _showQuizBottomSheet(context),
                        ),
                      ]);
                    }

                    // Principal: Show "Lectures" + "Create"
                    if (roleProvider.isPrincipal) {
                      buttons.addAll([
                        _buildActionButton(
                          context: context,
                          icon: Icons.book,
                          label: 'Lectures',
                          onPressed: () => Lecture_button_Conditional_Trigger(context),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.video_call,
                          label: 'Room List',
                          onPressed: () async {
                            final roleProvider = Provider.of<RoleProvider>(context, listen: false);

                            // For principals, ensure a valid teacher is selected by checking the DB.
                            if (roleProvider.isPrincipal) {
                              // Fetch the assigned teacher from the database for this meeting.
                              String teacherFromDB = await getAssignedTeacherFromDB(meeting.id);

                              // If we found a teacher from the DB, update our local variable.
                              if (teacherFromDB.isNotEmpty) {
                                selectedTeacher = teacherFromDB;
                              }

                              // Check if there's a valid teacher assignment.
                              if (selectedTeacher == null || selectedTeacher!.isEmpty) {
                                showSnackBarMessage(
                                  message: "Please assign meeting before proceeding.",
                                  context: context,
                                );
                                return; // Prevent navigation if assignment is missing.
                              }
                            }
                            final participantId = meeting.localParticipant.id;

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
                            // Leave the meeting.
                             meeting.leave();

                            // Navigate after a short delay.
                            Future.delayed(const Duration(milliseconds: 500), () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => TeacherScreen()),
                              );
                            });
                          },
                        ),

                      ]);
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: buttons,
                    );
                  },
                ),
              ),


              // Meeting Action Bar
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: !fullScreen
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                secondChild: const SizedBox.shrink(),
                firstChild: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.grey[900],
                  child: MeetingActionBar(
                    // Use the local state instead of checking audioStream directly
                    isMicEnabled: isLocalMicEnabled,
                    meeting: meeting,
                    isCamEnabled: videoStream != null,
                    isScreenShareEnabled: shareStream != null,
                    recordingState: recordingState,


                    onCallEndButtonPressed: () async {

                      final meetingState = Provider.of<MeetingState>(
                        context, listen: false);
                    DateTime end = DateTime.now();
                    meetingState.setEndTime(end);

                    // Compute the elapsed time if join time is available.
                    if (meetingState.joinTime != null) {
                      Duration elapsed = end.difference(meetingState
                          .joinTime!);

                      await saveElapsedTime(meeting.id, elapsed);
                    }

                      meeting.end();

                      Future.delayed(const Duration(milliseconds: 500), () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SplashScreen()),
                        );
                      });
                    },
                    onCallLeaveButtonPressed: () async {
                      final meetingState = Provider.of<MeetingState>(context, listen: false);
                      DateTime end = DateTime.now();
                      meetingState.setEndTime(end);

                      if (meetingState.joinTime != null) {
                        Duration elapsed = end.difference(meetingState.joinTime!);
                        await saveElapsedTime_students(meeting.id, participantId, elapsed); // Save student time
                      }
                      Future.delayed(const Duration(milliseconds: 250), () {

                      meeting.leave();

                      Future.delayed(const Duration(milliseconds: 500), () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SplashScreen()),
                            );
                          }
                        });
                      });
                    },

                    );
                    },



                    // Updated mic control callback
                    onMicButtonPressed: () {
                      setState(() {
                        // Toggle the local mic state first
                        isLocalMicEnabled = !isLocalMicEnabled;
                      });

                      // Then, call the meeting methods based on the updated state
                      if (isLocalMicEnabled) {
                        meeting.unmuteMic();
                      } else {
                        meeting.muteMic();
                      }
                    },
                    onCameraButtonPressed: () {
                      if (videoStream != null) {
                        meeting.disableCam();
                      } else {
                        meeting.enableCam();
                      }
                    },
                    onSwitchMicButtonPressed: (details) async {
                      List<AudioDeviceInfo>? outputDevice =
                      await VideoSDK.getAudioDevices();
                      double bottomMargin = (70.0 * outputDevice!.length);
                      final screenSize = MediaQuery.of(context).size;
                      await showMenu(
                        context: context,
                        color: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        position: RelativeRect.fromLTRB(
                          screenSize.width - details.globalPosition.dx,
                          details.globalPosition.dy - bottomMargin,
                          details.globalPosition.dx,
                          bottomMargin,
                        ),
                        items: outputDevice.map((e) {
                          return PopupMenuItem(
                            padding: EdgeInsets.zero,
                            value: e,
                            child: Container(
                              color: e.deviceId ==
                                  meeting.selectedSpeaker?.deviceId
                                  ? Colors.grey[700]
                                  : Colors.transparent,
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding:
                                  const EdgeInsets.fromLTRB(16, 10, 5, 10),
                                  child: Text(
                                    e.label,
                                    style: GoogleFonts.quicksand(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        elevation: 8.0,
                      ).then((value) {
                        if (value != null) {
                          meeting.switchAudioDevice(value);
                        }
                      });
                    },
                    onChatButtonPressed: () {
                      setState(() {
                        showChatSnackbar = false;
                      });
                      showModalBottomSheet(
                        context: context,
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height -
                                statusbarHeight),
                        isScrollControlled: true,
                        builder: (context) => ChatView(
                            key: const Key("ChatScreen"), meeting: meeting),
                      ).whenComplete(() {
                        setState(() {
                          showChatSnackbar = true;
                        });
                      });
                    },
                    onMoreOptionSelected: (option) {
                      if (option == "screenshare") {
                        if (remoteParticipantShareStream == null) {
                          if (shareStream == null) {
                            meeting.enableScreenShare();
                          } else {
                            meeting.disableScreenShare();
                          }
                        } else {
                          showSnackBarMessage(
                              message: "Someone is already presenting",
                              context: context);
                        }
                      } else if (option == "recording") {
                        if (recordingState == "RECORDING_STOPPING") {
                          showSnackBarMessage(
                              message: "Recording is in stopping state",
                              context: context);
                        } else if (recordingState == "RECORDING_STARTED") {
                          meeting.stopRecording();
                        } else if (recordingState == "RECORDING_STARTING") {
                          showSnackBarMessage(
                              message: "Recording is in starting state",
                              context: context);
                        } else {
                          meeting.startRecording();
                        }
                      } else if (option == "participants") {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: false,
                          builder: (context) =>
                              ParticipantList(meeting: meeting),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : const WaitingToJoin(),
    );
  }
  Future<void> saveElapsedTime(String meetingId, Duration elapsedTime) async {
    try {
      await FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(meetingId)
          .update({
        'elapsed_time': elapsedTime.inMinutes,
        'inmeeting': false,

      });
    } catch (e) {
      print("Error saving elapsed time: $e");
    }
  }
  Future<void> saveElapsedTime_students(String meetingId, String participantId, Duration elapsedTime) async {
    try {
      final DocumentReference participantDoc = FirebaseFirestore.instance
          .collection('meeting_record')
          .doc(meetingId)
          .collection('Stats')
          .doc(participantId);

      await participantDoc.update({
        'elapsed_time': elapsedTime.inMinutes,
        'inmeeting': false,

      });
    } catch (e) {
      print("Error saving elapsed time for $participantId: $e");
    }
  }


// Helper method to build action buttons
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  void Lecture_button_Conditional_Trigger(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => AudioBottomSheet(
        currentPlayingAudioUrl: _currentPlayingAudioUrl,
        onPlayAudio_broad: _playAudio_broad,
        onPlayAudio_stats: _playAudio_stats,
      ),
    );
  }























  // Updated Create More Button UI
  Widget buildCreateMoreButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 4,
      ),
      icon: const Icon(
        Icons.video_camera_front_outlined,
        color: Colors.white,
        size: 28,
      ),
      label: Text(
        "Create More Rooms",
        style: GoogleFonts.quicksand(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: () async {
        meeting.leave();
        final roleProvider = Provider.of<RoleProvider>(context, listen: false);
        Future.delayed(const Duration(milliseconds: 500), () {
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
        });
      },
    );
  }
  // Bottom Sheet for Quiz
  void _showQuizBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Screen',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: QuizWidget(meeting: meeting,)),
          ],
        ),
      ),
    );
  }
// Bottom Sheet for Audio List
  void Broadcast_Audio_List(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio List',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: _broadcasts
                    .expand((broadcast) => broadcast['audioFiles'] ?? [])
                    .map<Widget>((audioUrl) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AudioPlayerWidget(
                      audioUrl: audioUrl,
                      onPlay: () => _playAudio_broad(audioUrl),
                      isPlaying: _currentPlayingAudioUrl == audioUrl,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }





  void registerMeetingEvents(Room _meeting) {
    // Called when joined in meeting
    _meeting.on(
      Events.roomJoined,
          () {
        setState(() {
          meeting = _meeting;
          _joined = true;
        });

        if (kIsWeb || Platform.isWindows || Platform.isMacOS) {
          _meeting.switchAudioDevice(widget.selectedAudioOutputDevice!);
        }

        subscribeToChatMessages(_meeting);
      },
    );

    // Called when meeting is ended
    _meeting.on(Events.roomLeft, (String? errorMsg) {
      if (errorMsg != null) {
        showSnackBarMessage(
            message: "Meeting left due to $errorMsg !!", context: context);
      }
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => TeacherScreen()),
              (route) => false);
    });

    // Called when recording is started
    _meeting.on(Events.recordingStateChanged, (String status) {
      showSnackBarMessage(
          message:
          "Meeting recording ${status == "RECORDING_STARTING" ? "is starting" : status == "RECORDING_STARTED" ? "started" : status == "RECORDING_STOPPING" ? "is stopping" : "stopped"}",
          context: context);

      setState(() {
        recordingState = status;
      });
    });

    // Called when stream is enabled
    _meeting.localParticipant.on(Events.streamEnabled, (Stream _stream) {
      if (_stream.kind == 'video') {
        setState(() {
          videoStream = _stream;
        });
      } else if (_stream.kind == 'audio') {
        setState(() {
          audioStream = _stream;
        });
      } else if (_stream.kind == 'share') {
        setState(() {
          shareStream = _stream;
        });
      }
    });

    // Called when stream is disabled
    _meeting.localParticipant.on(Events.streamDisabled, (Stream _stream) {
      if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
        setState(() {
          videoStream = null;
        });
      } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
        setState(() {
          audioStream = null;
        });
      } else if (_stream.kind == 'share' && shareStream?.id == _stream.id) {
        setState(() {
          shareStream = null;
        });
      }
    });

    // Called when presenter is changed
    _meeting.on(Events.presenterChanged, (_activePresenterId) {
      Participant? activePresenterParticipant =
      _meeting.participants[_activePresenterId];

      // Get Share Stream
      Stream? _stream = activePresenterParticipant?.streams.values
          .singleWhere((e) => e.kind == "share");

      setState(() => remoteParticipantShareStream = _stream);
    });

    _meeting.on(
        Events.error,
            (error) => {
          showSnackBarMessage(
              message: error['name'].toString() +
                  " :: " +
                  error['message'].toString(),
              context: context)
        });
  }
  void subscribeToChatMessages(Room meeting) {
    meeting.pubSub.subscribe("CHAT", (message) {
      if (message.senderId != meeting.localParticipant.id) {
        if (mounted) {
          if (showChatSnackbar) {
            showSnackBarMessage(
                message: message.senderName + ": " + message.message,
                context: context);
          }
        }
      }
    });
  }
  Future<bool> _onWillPopScope() async {
    meeting.leave();

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    });
    return true;
  }
  @override
  void dispose() {
    _timer?.cancel(); // cancel teacher timer if any
    _remainingTimeSubscription?.cancel(); // stop listening to Firebase
    super.dispose();
    _broadcastSubscription
        ?.cancel(); // Stop the listener when the widget is disposed
    _audioFilesSubscription
        ?.cancel(); // Stop the listener when the widget is disposed

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
    _timer?.cancel(); // Cancel the timer on dispose
  }
}





class AudioBottomSheet extends StatefulWidget {
  final String? currentPlayingAudioUrl;
  final Function(String) onPlayAudio_broad;
  final Function(String) onPlayAudio_stats;

  const AudioBottomSheet({
    required this.currentPlayingAudioUrl,
    required this.onPlayAudio_broad,
    required this.onPlayAudio_stats,
    Key? key,
  }) : super(key: key);

  @override
  State<AudioBottomSheet> createState() => _AudioBottomSheetState();
}

class _AudioBottomSheetState extends State<AudioBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<RoleProvider>(
            builder: (context, roleProvider, child) {
              if (roleProvider.isTeacher || roleProvider.isPrincipal) {
                return Teacher_Lecture_card(
                  context,
                  widget.currentPlayingAudioUrl,
                  widget.onPlayAudio_broad,
                );
              } else if (roleProvider.isStudent) {
                return Student_Lecture_card(
                  context,
                  widget.currentPlayingAudioUrl,
                  widget.onPlayAudio_stats,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }


  Widget Teacher_Lecture_card(
      BuildContext context,
      String? currentPlayingAudioUrl,
      Function(String) onPlayAudio, // Accepts the function to call on play.
      ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Study_material').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No lectures found.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            );
          }
          final lectureDocs = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8.0),
            itemCount: lectureDocs.length,
            itemBuilder: (context, index) {
              final lecture = lectureDocs[index];
              final lectureName = lecture['TopicName'] ?? 'No Name';
              final lectureDescription = lecture['TopicDescription'] ?? 'No Description';
              final audioFiles = lecture['AudioFiles'] ?? [];
              final status = lecture['Status'] ?? 'Approved';
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 6.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with lecture title and controls.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lecture Name', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(lectureName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () {},
                                child: Text(status, style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('Study_material').doc(lecture.id).delete();
                                },
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Lecture Description', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(lectureDescription, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      if (audioFiles.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Lecture Audio Files', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ...audioFiles.map<Widget>((audioUrl) => Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: AudioPlayerWidget(
                                audioUrl: audioUrl,
                                onPlay: () => onPlayAudio(audioUrl),
                                // Compare the audioUrl with currentPlayingAudioUrl from parent.
                                isPlaying: currentPlayingAudioUrl == audioUrl,
                              ),
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget Student_Lecture_card(
      BuildContext context,
      String? currentPlayingAudioUrl, // Current playing audio URL flag from parent.
      Function(String) onPlayAudio, // Playback function.
      ) {
    final principalProvider = Provider.of<PrincipalProvider>(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: principalProvider.teacherCards.isEmpty
          ? Center(
        child: Text(
          'No approved content available.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 38.0),
        itemCount: principalProvider.teacherCards.length,
        itemBuilder: (context, index) {
          final card = principalProvider.teacherCards[index];
          final audioFiles = List<String>.from(card['audioFiles'] as List? ?? []);

          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('List Of Lectures', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  if (audioFiles.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: audioFiles.map<Widget>((audioUrl) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: AudioPlayerWidget(
                            audioUrl: audioUrl,
                            onPlay: () => onPlayAudio(audioUrl),
                            isPlaying: currentPlayingAudioUrl == audioUrl,
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'No audio files for this lecture.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


}

/*

class Create_lecture extends StatefulWidget {
  const Create_lecture({super.key});

  @override
  State<Create_lecture> createState() => _Create_LectureState();
}

class _Create_LectureState extends State<Create_lecture> {
  final CreateTopicProvider assignmentProvider = CreateTopicProvider();

  final List<File> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles
              .addAll(result.paths.map((path) => File(path!)).toList());
        });
      } else {
        print("No files selected.");
      }
    } catch (e) {
      print("Error picking files: $e");
    }
  }

  Future<List<String>> _uploadFilesToFirebase() async {
    List<String> downloadUrls = [];
    const teachername = 'dummy teacher';

    try {
      for (var file in _selectedFiles) {
        final fileName = file.path.split('/').last;
        if (['.mp3', '.wav', '.m4a'].any((ext) => fileName.endsWith(ext))) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('study_materials/$teachername/$fileName');
          final uploadTask = ref.putFile(file);

          // Wait for the upload to complete and get the URL
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          downloadUrls.add(downloadUrl);
        } else {
          print("Unsupported file format for $fileName");
        }
      }
    } catch (e) {
      print("Error uploading files: $e");
    }

    return downloadUrls;
  }

  Future<void> _saveToFirestore(CreateTopicProvider assignmentProvider) async {
    setState(() {
      _isUploading = true;
    });

    final teacherId = FirebaseAuth.instance.currentUser?.uid;
    final audioUrls = await _uploadFilesToFirebase(); // Upload all files

    final docRef =
        FirebaseFirestore.instance.collection('Study_material').doc();
    await docRef.set({
      'TopicName': assignmentProvider.assignmentName,
      'ClassSelected': assignmentProvider.selectedClass,
      'SubjectSelected': assignmentProvider.selectedSubject,
      'TopicDescription': assignmentProvider.instructions,
      'TeacherId': teacherId,
      'AudioFiles': audioUrls, // Save all audio URLs as an array
      'CreatedAt': FieldValue.serverTimestamp(),
      'Status': assignmentProvider.status,
    });

    setState(() {
      _isUploading = false;
      _selectedFiles.clear();
    });

    _showSnackbar_connection(context, 'Topic added successfully!');
  }

  void _showSnackbar_connection(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: GoogleFonts.quicksand().fontFamily,
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
        duration: const Duration(seconds: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90), // Set the height
        child: AppBar(
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/back_icon.svg',
              width: 25, // Adjust the size as needed
              height: 25, // Adjust the size as needed
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          title: Text(
            "Upload Lectures",
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF044B89),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: "Lecture Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(width: 1, color: Colors.black),
                        ),
                      ),
                      onChanged: (value) {
                        assignmentProvider.setTopicName(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: "Lecture Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(width: 1, color: Colors.black),
                        ),
                      ),
                      maxLines: 5,
                      onChanged: (value) {
                        assignmentProvider.setInstructions(value);
                      },
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black12,
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF044B89),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFiles.isNotEmpty
                                  ? "${_selectedFiles.length} file(s) selected"
                                  : "Study Material(s)",
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 46),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isUploading
                            ? null
                            : () => _saveToFirestore(assignmentProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF044B89),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isUploading ? "Submitting..." : "Upload",
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
