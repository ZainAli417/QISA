import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';
import 'package:videosdk_flutter_example/screens/conference-call/conference_meeting_screen.dart';
import '../constants/QrCode.dart';
import '../providers/teacher_provider.dart';
import '../providers/topic_provider.dart';
import 'Quiz and Audio/Broadcast_Screen.dart';
import 'Quiz and Audio/Audio_Player_UI.dart';
import 'common/join_screen.dart';

class TeacherScreen extends StatefulWidget {
  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  bool isRejoin = false;
  get token => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiJhNmQ5OTI3NC1hMTIyLTRiYzMtYmJhOS0wNDYyOTcyNWNiMDQiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTczNjIyMzYzNywiZXhwIjoxODk0MDExNjM3fQ.TdZwUNK6jQ-SZjCvabdIvnnbpk2wWvSCruRSxLKEMsY';
  List<Map<String, dynamic>> statsData = [];
  Map<String, Map<String, dynamic>> participantStats = {};
  late StreamSubscription<QuerySnapshot> statsSubscription;
  late Room meeting;
String meetingId= '';


// Inside your main build method:
  Widget build(BuildContext context) {
    final teacherProvider = Provider.of<TeacherProvider>(context);
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(170),
          child: Stack(
            children: [
              Container(
                height: 170,
                decoration: const BoxDecoration(
                  color: Color(0xFF044B89),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),

              Positioned(
                top: 60,
                left: 30,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      backgroundImage: AssetImage(teacherProvider.avatarUrl),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      teacherProvider.teacherName,
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 50),
                    _buildLogoutButton(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 123),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  labelColor: const Color(0xFF044B89),
                  unselectedLabelColor: Colors.white,
                  labelStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, fontSize: 16),
                  unselectedLabelStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, size: 23),
                          SizedBox(width: 5),
                          Text("Dashboard"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cast_for_education_rounded, size: 23),
                          SizedBox(width: 5),
                          Text("Broadcast"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Body Section with Firestore Data
        body: TabBarView(
          children: [
            // Home Tab
            Column(
              children: [

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('meeting_record')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/no_data.jpg',
                              width: 400,
                              height: 500,
                            ),
                            Text(
                              'No Meetings Created Yet',
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      } else {
                        var meetings = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: meetings.length,
                          itemBuilder: (context, index) {
                            // Use actual meeting data here
                            var data = meetings[index].data()
                            as Map<String, dynamic>;
                            var roomName =
                                data['room_name'] ?? 'Unknown Room';
                            var roomId = data['room_id'] ?? 'N/A'; // Use this
                            var assignedTo =
                                data['assigned_to'] ?? 'Unassigned';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1, horizontal: 10),
                              child: SizedBox(
                                height: 250, // Reduced height after removing direct graphs
                                width: 500,
                                child: Card(
                                  color: Colors.white,
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),


                                  child: Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                        leading: const Icon(
                                          Icons.meeting_room,
                                          color: Color(0xFF044B89),
                                          size: 30,
                                        ),
                                        title: Text(
                                          'Meeting ID: $roomId',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Assigned To: $assignedTo',
                                          style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const Divider(height: 1, color: Colors.grey),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.video_call, color: Colors.white),
                                              label: Text(
                                                'Join',
                                                style: GoogleFonts.quicksand(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ConferenceMeetingScreen(
                                                      meetingId: roomId,
                                                      token: token,
                                                      displayName: roomName,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.bar_chart, color: Colors.white),
                                              label: Text(
                                                'View Stats',
                                                style: GoogleFonts.quicksand(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () async {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => StatsDialog(
                                                    meetingId: roomId,
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.qr_code_rounded, color: Colors.black87, size: 30),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  backgroundColor: Colors.grey.shade50,
                                                  context: context,
                                                  builder: (context) => QrShareWidget(meetingId: roomId, hostedBy: assignedTo),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Participant Count Capsule
                                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('meeting_record')
                                                  .doc(roomId)
                                                  .collection('Stats')
                                                  .where('inmeeting', isEqualTo: true)
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  return Text('Error: ${snapshot.error}');
                                                }
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                }
                                                final participantCount = snapshot.data!.docs.length;
                                                return Chip(
                                                  avatar: const Icon(Icons.people, size: 18, color: Colors.black87),
                                                  label: Text(
                                                    'Participants: $participantCount',
                                                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
                                                  ),
                                                  backgroundColor: Colors.grey[200],
                                                );
                                              },
                                            ),

                                            // Meeting Elapsed Time Capsule
                                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('meeting_record')
                                                  .doc(roomId)
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  print('Firestore Error: ${snapshot.error}');
                                                  return Text('Error: ${snapshot.error}');
                                                }
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                }

                                                final data = snapshot.data?.data();
                                                print('Retrieved Firestore Data: $data'); // Debugging output

                                                final elapsedTime = data?['elapsed_time'];

                                                String displayTime;
                                                if (elapsedTime is String) {
                                                  displayTime = elapsedTime; // "IN PROGRESS"
                                                } else if (elapsedTime is num) {
                                                  displayTime = '$elapsedTime min'; // Convert number to "X min"
                                                } else {
                                                  displayTime = 'N/A'; // Fallback for null or unexpected values
                                                }

                                                return Chip(
                                                  avatar: const Icon(Icons.access_time, size: 18, color: Colors.black87),
                                                  label: Text(
                                                    'Elapsed: $displayTime',
                                                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
                                                  ),
                                                  backgroundColor: Colors.grey[200],
                                                );
                                              },
                                            ),

                                          ],
                                        ),
                                      ),
                                    ],
                                  ),




                                    ),
                                ),

                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            // Broadcast Tab
            const Broadcasting(), // Replace with your actual Upload/Broadcast widget
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const JoinScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/fab.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      ),
      icon: const Icon(Icons.logout_outlined, color: Colors.white),
      label: Text(
        "Logout",
        style: GoogleFonts.quicksand(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );
      },
    );
  }
}

class StatsDialog extends StatefulWidget {
  final String meetingId;
  const StatsDialog({Key? key, required this.meetingId}) : super(key: key);

  @override
  _StatsDialogState createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> statsData = [];
  Map<String, Map<String, dynamic>> participantStats = {};
  late StreamSubscription<QuerySnapshot> statsSubscription;
  late Room meeting;

  @override
  void initState() {
    super.initState();
    listenToStats(); // Start listening to the Firestore collection
  }


  @override
  void dispose() {
    statsSubscription.cancel(); // Cancel subscription on dispose
    super.dispose();
  }

// Function to listen to stats changes in Firestore
  void listenToStats() {
    statsSubscription = FirebaseFirestore.instance
        .collection('meeting_record')
        .doc(widget.meetingId)
        .collection('Stats')

        .where('role', isEqualTo: 'Student') // Filter only students
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> fetchedData = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'displayName': data['displayName'],
          'audioPlayedCount': data['audioPlayedCount'] ?? 0,
          'Q_marks': data['Q_marks'] ?? 0,
          'joinTime': (data['joinTime'] is Timestamp)
              ? (data['joinTime'] as Timestamp).toDate()
              : DateFormat('HH:mm:ss').parse(data['joinTime']),
        };
      }).toList();

      setState(() {
        statsData = fetchedData;
      });
    });
  }




  Widget buildAudioAndQuizGraph(List<Map<String, dynamic>> statsData) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: const NumericAxis(
        interval: 5,
        maximum: 30,
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: statsData,
          xValueMapper: (data, _) => data['displayName'],
          yValueMapper: (data, _) => data['audioPlayedCount'],
          name: 'Audio Replay',
          color: const Color(0xFF4CAF50),
          width: 0.2,
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: statsData,
          xValueMapper: (data, _) => data['displayName'],
          yValueMapper: (data, _) => data['Q_marks'],
          name: 'Quiz Marks(Out Of 40)',
          color: const Color(0xFFF44336),
          width: 0.2,
        ),
      ],
      legend: const Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget buildJoinTimeGraph(List<Map<String, dynamic>> statsData) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        interval: 3600,
        maximum: 86400,
        labelFormat: '{value} s',
        title: AxisTitle(text: 'Join Time'),
        axisLabelFormatter: (args) {
          int totalSeconds = args.value.toInt();
          int hours = totalSeconds ~/ 3600;
          int minutes = (totalSeconds % 3600) ~/ 60;
          int seconds = totalSeconds % 60;
          return ChartAxisLabel(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            null,
          );
        },
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: statsData,
          xValueMapper: (data, _) => data['displayName'],
          yValueMapper: (data, _) {
            DateTime joinTime = data['joinTime'];
            return (joinTime.hour * 3600) +
                (joinTime.minute * 60) +
                joinTime.second;
          },
          name: 'Join Time',
          color: const Color(0xFF2196F3),
          width: 0.2,
        ),
      ],
      legend: Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: statsData.isNotEmpty
                  ? Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: buildAudioAndQuizGraph(statsData),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: buildJoinTimeGraph(statsData),
                      ),
                    ],
                  ),
                  // Left arrow button
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () {
                        if (_currentPage > 0) {
                          _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // Right arrow button
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () {
                        if (_currentPage < 1) {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
                  : Center(
                child: Text(
                  "No data received yet",
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
