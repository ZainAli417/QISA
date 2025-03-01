// ignore_for_file: non_constant_identifier_names, dead_code
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/screens/TeacherScreen.dart';
import 'package:videosdk_flutter_example/screens/conference-call/conference_meeting_screen.dart';
import 'package:videosdk_flutter_example/utils/api.dart';
import 'package:videosdk_flutter_example/widgets/common/joining/join_options.dart';
import '../../constants/colors.dart';
import '../../providers/role_provider.dart';
import '../../utils/toast.dart';
import '../../widgets/common/joining/join_view.dart';
import '../SplashScreen.dart';
import '../one-to-one/one_to_one_meeting_screen.dart';
import '../../widgets/common/pre_call/dropdowns_Web.dart';
import '../../widgets/common/pre_call/selectAudioDevice.dart';
import '../../widgets/common/pre_call/selectVideoDevice.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({Key? key}) : super(key: key);

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> with WidgetsBindingObserver {
  String _token = "";

  // Disable any camera/mic preview by default.
  bool isMicOn = false;
  bool isCameraOn = false;

  CustomTrack? cameraTrack;
  CustomTrack? microphoneTrack;
  RTCVideoRenderer? cameraRenderer;

  bool? isCameraPermissionAllowed =
  !kIsWeb && (Platform.isMacOS || Platform.isWindows) ? true : false;
  bool? isMicrophonePermissionAllowed =
  !kIsWeb && (Platform.isMacOS || Platform.isWindows) ? true : false;

  VideoDeviceInfo? selectedVideoDevice;
  AudioDeviceInfo? selectedAudioOutputDevice;
  AudioDeviceInfo? selectedAudioInputDevice;
  List<VideoDeviceInfo>? videoDevices;
  List<AudioDeviceInfo>? audioDevices;
  List<AudioDeviceInfo> audioInputDevices = [];
  List<AudioDeviceInfo> audioOutputDevices = [];

  late Function handler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(
      const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await fetchToken(context);
      if (mounted) setState(() => _token = token);
    });
    checkandReqPermissions();
    subscribe();
  }

  void updateselectedAudioOutputDevice(AudioDeviceInfo? device) {
    if (device?.deviceId != selectedAudioOutputDevice?.deviceId) {
      setState(() {
        selectedAudioOutputDevice = device;
      });
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // No microphone track disposal or initialization.
      }
    }
  }

  void updateselectedAudioInputDevice(AudioDeviceInfo? device) {
    if (device?.deviceId != selectedAudioInputDevice?.deviceId) {
      setState(() {
        selectedAudioInputDevice = device;
      });
    }
  }

  void updateSelectedVideoDevice(VideoDeviceInfo? device) {
    if (device?.deviceId != selectedVideoDevice?.deviceId) {
      setState(() {
        selectedVideoDevice = device;
      });
    }
  }

  Future<void> checkBluetoothPermissions() async {
    try {
      bool bluetoothPerm = await VideoSDK.checkBluetoothPermission();
      if (!bluetoothPerm) {
        await VideoSDK.requestBluetoothPermission();
      }
    } catch (e) {}
  }

  void getDevices() async {
    if (isCameraPermissionAllowed == true) {
      videoDevices = await VideoSDK.getVideoDevices();
      setState(() {
        selectedVideoDevice = videoDevices?.first;
      });
    }
    if (isMicrophonePermissionAllowed == true) {
      audioDevices = await VideoSDK.getAudioDevices();
      if (!kIsWeb &&
          !Platform.isMacOS &&
          !Platform.isWindows) {
        setState(() {
          selectedAudioOutputDevice = audioDevices?.first;
        });
      } else {
        // Optimized filtering using where()
        audioInputDevices =
            audioDevices!.where((d) => d.kind == 'audioinput').toList();
        audioOutputDevices =
            audioDevices!.where((d) => d.kind != 'audioinput').toList();
        setState(() {
          selectedAudioOutputDevice = audioOutputDevices.first;
          selectedAudioInputDevice = audioInputDevices.first;
        });
      }
    }
  }

  void checkandReqPermissions([Permissions? perm]) async {
    perm ??= Permissions.audio_video;
    try {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        final permissions = await VideoSDK.checkPermissions();
        if (perm == Permissions.audio || perm == Permissions.audio_video) {
          if (permissions['audio'] != true) {
            final reqPermissions =
            await VideoSDK.requestPermissions(Permissions.audio);
            setState(() {
              isMicrophonePermissionAllowed = reqPermissions['audio'];
            });
          } else {
            setState(() {
              isMicrophonePermissionAllowed = true;
            });
          }
        }
        if (perm == Permissions.video || perm == Permissions.audio_video) {
          if (permissions['video'] != true) {
            final reqPermissions =
            await VideoSDK.requestPermissions(Permissions.video);
            setState(() => isCameraPermissionAllowed = reqPermissions['video']);
          } else {
            setState(() => isCameraPermissionAllowed = true);
          }
        }
        if (!kIsWeb && Platform.isAndroid) {
          await checkBluetoothPermissions();
        }
      }
      getDevices();
    } catch (e) {}
  }

  void checkPermissions() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      final permissions = await VideoSDK.checkPermissions();
      setState(() {
        isMicrophonePermissionAllowed = permissions['audio'];
        isCameraPermissionAllowed = permissions['video'];
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        checkPermissions();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      // Keeping original logic
        throw UnimplementedError();
    }
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final viewportConstraints = MediaQuery.of(context).size;
    // Cache the desktop/platform check.
    final bool isDesktop = kIsWeb || Platform.isWindows || Platform.isMacOS;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {},
      child: Scaffold(
        appBar: !kIsWeb && (Platform.isAndroid || Platform.isIOS)
            ? AppBar(
          flexibleSpace: Align(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 40, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 27,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final roleProvider = Provider.of<RoleProvider>(
                        context,
                        listen: false,
                      );
                      if (roleProvider.isPrincipal) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  TeacherScreen(),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  SplashScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  // Removed the Row containing volume_up and camera_alt_rounded IconButton
                  // Row(
                  //   children: [
                  //     IconButton(
                  //       icon: const Icon(
                  //         Icons.volume_up,
                  //         size: 27,
                  //         color: Colors.white,
                  //       ),
                  //       onPressed: () {
                  //         showModalBottomSheet<void>(
                  //           context: context,
                  //           builder: (BuildContext context) {
                  //             return Container(
                  //               color: black750,
                  //               child: Padding(
                  //                 padding: const EdgeInsets.symmetric(
                  //                     vertical: 10),
                  //                 child: SelectAudioDevice(
                  //                   isMicrophonePermissionAllowed:
                  //                   isMicrophonePermissionAllowed,
                  //                   selectedAudioOutputDevice:
                  //                   selectedAudioOutputDevice,
                  //                   audioDevices: audioDevices,
                  //                   onAudioDeviceSelected:
                  //                   updateselectedAudioOutputDevice,
                  //                 ),
                  //               ),
                  //             );
                  //           },
                  //         );
                  //       },
                  //     ),
                  //     IconButton(
                  //       icon: const Icon(
                  //         Icons.camera_alt_rounded,
                  //         size: 27,
                  //         color: Colors.white,
                  //       ),
                  //       onPressed: () {
                  //         showModalBottomSheet<void>(
                  //           context: context,
                  //           builder: (BuildContext context) {
                  //             return Container(
                  //               color: black750,
                  //               child: Padding(
                  //                 padding: const EdgeInsets.symmetric(
                  //                     vertical: 10),
                  //                 child: SelectVideoDevice(
                  //                   isCameraPermissionAllowed:
                  //                   isCameraPermissionAllowed,
                  //                   selectedVideoDevice:
                  //                   selectedVideoDevice,
                  //                   videoDevices: videoDevices,
                  //                   onVideoDeviceSelected:
                  //                   updateSelectedVideoDevice,
                  //                 ),
                  //               ),
                  //             );
                  //           },
                  //         );
                  //       },
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
          backgroundColor: black750,
          elevation: 0,
        )
            : null,
        backgroundColor: primaryColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
              Widget _buildContent() {
                return isDesktop
                    ? ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Container(
                    margin: EdgeInsets.only(top: maxWidth / 10),
                    child: JoinOptions(
                      maxWidth: maxWidth,
                      onClickMeetingJoin: _onClickMeetingJoin,
                    ),
                  ),
                )




                    : SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        JoinOptions(
                          maxWidth: maxWidth,
                          onClickMeetingJoin: _onClickMeetingJoin,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _buildContent();
            },
          ),
        ),
      ),
    );
  }


  void _onClickMeetingJoin(meetingId, callType, displayName) async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    if (displayName.toString().isEmpty) {
      displayName = "Guest";
    }

    if (roleProvider.isPrincipal) {

      createAndJoinMeeting(callType, displayName);
    } else {
      joinMeeting(callType, displayName, meetingId);
    }
  }

  Future<void> createAndJoinMeeting(callType, displayName) async {
    try {
      var _meetingID = await createMeeting(_token);
      if (mounted) {
        setState(() {
          cameraRenderer = null;
        });
        unsubscribe();

        if (callType == "GROUP") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConferenceMeetingScreen(
                token: _token,
                meetingId: _meetingID,
                displayName: displayName,
                micEnabled: isMicOn,
                camEnabled: isCameraOn,
                selectedAudioOutputDevice: selectedAudioOutputDevice,
                selectedAudioInputDevice: selectedAudioInputDevice,
                cameraTrack: cameraTrack,
                micTrack: microphoneTrack,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OneToOneMeetingScreen(
                  token: _token,
                  meetingId: _meetingID,
                  displayName: displayName,
                  micEnabled: isMicOn,
                  camEnabled: isCameraOn,
                  selectedAudioOutputDevice: selectedAudioOutputDevice,
                  selectedAudioInputDevice: selectedAudioInputDevice,
                  cameraTrack: cameraTrack,
                  micTrack: microphoneTrack),
            ),
          );
        }
      }
    } catch (error) {
      showSnackBarMessage(message: error.toString(), context: context);
    }
  }

  Future<void> joinMeeting(callType, displayName, meetingId) async {
    if (meetingId.isEmpty) {
      showSnackBarMessage(
          message: "Please enter Valid Meeting ID", context: context);
      return;
    }
    var validMeeting = await validateMeeting(_token, meetingId);
    if (validMeeting) {
      if (mounted) {
        setState(() {
          cameraRenderer = null;
        });
        unsubscribe();

        if (callType == "GROUP") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConferenceMeetingScreen(
                  token: _token,
                  meetingId: meetingId,
                  displayName: displayName,
                  micEnabled: isMicOn,
                  camEnabled: isCameraOn,
                  selectedAudioOutputDevice: selectedAudioOutputDevice,
                  selectedAudioInputDevice: selectedAudioInputDevice,
                  cameraTrack: cameraTrack,
                  micTrack: microphoneTrack),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OneToOneMeetingScreen(
                  token: _token,
                  meetingId: meetingId,
                  displayName: displayName,
                  micEnabled: isMicOn,
                  camEnabled: isCameraOn,
                  selectedAudioOutputDevice: selectedAudioOutputDevice,
                  selectedAudioInputDevice: selectedAudioInputDevice,
                  cameraTrack: cameraTrack,
                  micTrack: microphoneTrack),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        showSnackBarMessage(message: "Invalid Meeting ID", context: context);
      }
    }
  }

  void subscribe() {
    handler = (devices) {
      getDevices();
    };
    VideoSDK.on(Events.deviceChanged, handler);
  }

  void unsubscribe() {
    VideoSDK.off(Events.deviceChanged, handler);
  }

  @override
  void dispose() {
    unsubscribe();
    SystemChrome.setPreferredOrientations(
      const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
    super.dispose();
  }
}
