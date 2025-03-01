import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/shedule_provider.dart';

class ScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90), // Set the height
        child: AppBar(
          backgroundColor: Color(0xFF044B89),
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/images/back_icon.svg',
              color: Color(0xFF044B89),
            ),
            onPressed: () {},
          ),
          title: Text(
            "Up Coming Meetings",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDaysList(context, scheduleProvider), // Moved below the AppBar
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _buildScheduleList(scheduleProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList(
      BuildContext context, ScheduleProvider scheduleProvider) {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(15, 15, 5, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (index) {
          bool isSelected = scheduleProvider.selectedDayIndex == index;
          return GestureDetector(
            onTap: () => scheduleProvider.setSelectedDayIndex(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF044B89) : Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                days[index],
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : const Color(0xFF044B89),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget? _buildScheduleList(ScheduleProvider scheduleProvider) {
    final scheduleList = scheduleProvider.getScheduleForSelectedDay();
    if (scheduleList.isEmpty) {
      return Center(
        child: SvgPicture.asset(
          'assets/images/fileNotFound.svg', // Path to your 'notfound.svg' image
          //  width: 150,
          //  height: 150,
        ),
      );
    }
    Text(
      "Nothing Planned Now",
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
    return null;
  }
}
