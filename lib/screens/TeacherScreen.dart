import 'dart:async';
import 'dart:io';
import 'dart:ui';
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
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';
import 'package:videosdk_flutter_example/screens/conference-call/conference_meeting_screen.dart';
import '../constants/QrCode.dart';
import '../providers/teacher_provider.dart';
import '../providers/topic_provider.dart';
import 'BOTTOM_SHEETS/Broadcast_Screen.dart';
import 'common/join_screen.dart';
// Define a tuple type if needed (or you can use a package like "tuple")
class Tuple2<A, B> {
  final A item1;
  final B item2;
  Tuple2(this.item1, this.item2);
}
class TeacherScreen extends StatefulWidget {
  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {

  late final AsyncSnapshot<QuerySnapshot> snapshot;
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
                  color: Color(0xFF4A90D1),
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
                    const SizedBox(width: 100),
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
                            var data = meetings[index].data() as Map<String, dynamic>;
                            var roomName = data['room_name'] ?? 'Unknown Room';
                            var roomId = data['room_id'] ?? 'N/A';
                            var assignedTo = data['assigned_to'] ?? 'Unassigned';

                            // Combined stream for meeting document and stats collection.
                            final combinedStream = Rx.combineLatest2<
                                DocumentSnapshot<Map<String, dynamic>>,
                                QuerySnapshot<Map<String, dynamic>>,
                                Tuple2<DocumentSnapshot<Map<String, dynamic>>,
                                    QuerySnapshot<Map<String, dynamic>>>>(
                              FirebaseFirestore.instance
                                  .collection('meeting_record')
                                  .doc(roomId)
                                  .snapshots(),
                              FirebaseFirestore.instance
                                  .collection('meeting_record')
                                  .doc(roomId)
                                  .collection('Stats')
                                  .where('inmeeting', isEqualTo: true)
                                  .snapshots(),
                                  (doc, stats) => Tuple2(doc, stats),
                            );

                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 1, horizontal: 10),
                              child: SizedBox(
                                height: 250,
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
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 16),
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
                                          style: GoogleFonts.quicksand(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1, color: Colors.grey),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.video_call,
                                                  color: Colors.white),
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
                                                    builder: (context) =>
                                                        ConferenceMeetingScreen(
                                                          meetingId: roomId,
                                                          token: token,
                                                          displayName: roomName,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.bar_chart,
                                                  color: Colors.white),
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
                                                showGeneralDialog(
                                                  context: context,
                                                  barrierLabel: "Stats",
                                                  barrierDismissible: true,
                                                  barrierColor: Colors.transparent, // We'll apply custom blur
                                                  transitionDuration: const Duration(milliseconds: 300),
                                                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                                                    final offset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                                                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                                                    return SlideTransition(position: offset, child: child);
                                                  },
                                                  pageBuilder: (context, animation, secondaryAnimation) {
                                                    return GestureDetector(
                                                      onTap: () => Navigator.of(context).pop(), // Close on outside tap
                                                      child: BackdropFilter(
                                                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                                        child: Scaffold(
                                                          backgroundColor: Colors.transparent,
                                                          body: Align(
                                                            alignment: Alignment.bottomCenter,
                                                            child: StatsBottomSheet(meetingId: roomId),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },

                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.qr_code_rounded,
                                                  color: Colors.black87, size: 30),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  backgroundColor: Colors.grey.shade50,
                                                  context: context,
                                                  builder: (context) =>
                                                      QrShareWidget(
                                                        meetingId: roomId,
                                                        hostedBy: assignedTo,
                                                      ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Combined StreamBuilder for participant count and elapsed time.
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: StreamBuilder<
                                            Tuple2<
                                                DocumentSnapshot<Map<String, dynamic>>,
                                                QuerySnapshot<Map<String, dynamic>>>>(
                                          stream: combinedStream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }
                                            final meetingDoc = snapshot.data!.item1;
                                            final statsSnapshot = snapshot.data!.item2;
                                            final participantCount =
                                                statsSnapshot.docs.length;

                                            // Retrieve elapsed time from the meeting document.
                                            final meetingData = meetingDoc.data();
                                            final elapsedTime = meetingData?['elapsed_time'];

                                            String displayTime;
                                            if (elapsedTime is String) {
                                              displayTime = elapsedTime; // e.g. "IN PROGRESS"
                                            } else if (elapsedTime is num) {
                                              displayTime = '$elapsedTime min';
                                            } else {
                                              displayTime = 'N/A';
                                            }

                                            return Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                Chip(
                                                  avatar: const Icon(Icons.people,
                                                      size: 18, color: Colors.black87),
                                                  label: Text(
                                                    'Participants: $participantCount',
                                                    style: GoogleFonts.quicksand(
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                  backgroundColor: Colors.grey[200],
                                                ),
                                                Chip(
                                                  avatar: const Icon(Icons.access_time,
                                                      size: 18, color: Colors.black87),
                                                  label: Text(
                                                    'Elapsed: $displayTime',
                                                    style: GoogleFonts.quicksand(
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                  backgroundColor: Colors.grey[200],
                                                ),
                                              ],
                                            );
                                          },
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
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



class StatsBottomSheet extends StatefulWidget {
  final String meetingId;
  const StatsBottomSheet({Key? key, required this.meetingId}) : super(key: key);

  @override
  _StatsBottomSheetState createState() => _StatsBottomSheetState();
}

class _StatsBottomSheetState extends State<StatsBottomSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> statsData = [];
  late StreamSubscription<QuerySnapshot> statsSubscription;

  @override
  void initState() {
    super.initState();
    listenToStats();
  }

  @override
  void dispose() {
    statsSubscription.cancel();
    super.dispose();
  }

  void listenToStats() {
    statsSubscription = FirebaseFirestore.instance
        .collection('meeting_record')
        .doc(widget.meetingId)
        .collection('Stats')
        .where('role', isEqualTo: 'Student')
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> fetchedData = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'displayName': data['displayName'],
          'audioPlayedCount': data['audioPlayedCount'] ?? 0,
          'Q_marks': data['Q_marks'] ?? 0,
          'elapsed_time': data['elapsed_time'],
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
          name: 'Quiz Marks (Out Of 40)',
          color: const Color(0xFFF44336),
          width: 0.2,
        ),
      ],
      legend: const Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }


  Widget buildElapsedTimeGraph(List<Map<String, dynamic>> statsData) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: const NumericAxis(
        interval: 2,
        maximum: 30,
        title: AxisTitle(text: 'Elapsed Time (mins)'),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: statsData,
          xValueMapper: (data, _) => data['displayName'],
          yValueMapper: (data, _) {
            var elapsed = data['elapsed_time'];
            if (elapsed is int) return elapsed;
            if (elapsed is double) return elapsed.toInt();
            return 0;
          },
          name: 'Elapsed Time',
          color: const Color(0xFF2BDD7E),
          width: 0.1,
        ),
      ],
      legend: const Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }
  Future<void> generateAndSharePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Meeting Stats - ${widget.meetingId}'),
          ),
        pw.TableHelper. fromTextArray(
            headers: [
              'Name',
              'Audio Replays',
              'Quiz Marks',
              'Elapsed Time (min)',
            ],
            data: statsData.map((data) {
              final elapsed = data['elapsed_time'];
              return [
                data['displayName'],
                data['audioPlayedCount'].toString(),
                data['Q_marks'].toString(),
                (elapsed is int ? elapsed : (elapsed is double ? elapsed.toInt() : 0)).toString(),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'meeting_stats_${widget.meetingId}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),

      child: Column(

        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Row(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: generateAndSharePDF,
                tooltip: 'Download as PDF',
              ),
            ],
          ),
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
                    buildAudioAndQuizGraph(statsData),
                    buildElapsedTimeGraph(statsData),
                  ],
                ),
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutSine,
                        );
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
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
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
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
