import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:videosdk_flutter_example/constants/colors.dart';
import 'package:videosdk_flutter_example/utils/spacer.dart';
import 'package:videosdk_flutter_example/utils/toast.dart';

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
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        if (!widget.isCreateMeeting) ...[
          Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                fit: BoxFit.cover,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      setState(() {
                        _meetingId = barcode.rawValue!;
                      });
                    }
                  }
                },
              ),
            ),
          ),
          const VerticalSpacer(20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
              onChanged: ((value) => _meetingId = value),
              controller: TextEditingController(text: _meetingId),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.meeting_room_outlined, color: textGray),
                labelText: "Meeting Code",
                hintText: "Scan QR code or enter meeting code",
                hintStyle:  GoogleFonts.quicksand(color: Colors.white70,fontSize: 15,fontWeight: FontWeight.w600),
                labelStyle:  GoogleFonts.quicksand(color: Colors.white70,fontSize: 15,fontWeight: FontWeight.w600),
                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(width: 1,style: BorderStyle.solid,color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
        const VerticalSpacer(20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            onChanged: ((value) => _displayName = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
              labelText: "Your Name",
              labelStyle:  GoogleFonts.quicksand(color: Colors.white70,fontSize: 15,fontWeight: FontWeight.w600),
              hintText: "Enter your name here",
              hintStyle:  GoogleFonts.quicksand(color: Colors.white70,fontSize: 15,fontWeight: FontWeight.w600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(width: 1,style: BorderStyle.solid,color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white70),
              ),
            ),
          ),
        ),
        const VerticalSpacer(25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MaterialButton(
            minWidth: ResponsiveValue<double>(
              context,
              conditionalValues: [
                Condition.equals(name: MOBILE, value: maxWidth / 1.9),
                Condition.equals(name: TABLET, value: maxWidth / 1.3),
                Condition.equals(name: DESKTOP, value: maxWidth / 3),
              ],
            ).value,
            height: 50,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.blue,
            child: const Text(
              "Join Meeting +",
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              if (_displayName.trim().isEmpty) {
                showSnackBarMessage(message: "Please enter name", context: context);
                return;
              }
              if (!widget.isCreateMeeting && _meetingId.trim().isEmpty) {
                showSnackBarMessage(message: "Please enter meeting id", context: context);
                return;
              }
              widget.onClickMeetingJoin(_meetingId.trim(), meetingMode, _displayName.trim());
            },
          ),
        ),
        const VerticalSpacer(20),
      ],
    );
  }
}
