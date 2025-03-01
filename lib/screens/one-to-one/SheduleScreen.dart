import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/shedule_provider.dart';


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
            onPressed: () {

            },
          ),

          title: Text(
            "Schedule",
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

  Widget _buildDaysList(BuildContext context, ScheduleProvider scheduleProvider) {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(15,15,5,5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (index) {
          bool isSelected = scheduleProvider.selectedDayIndex == index;
          return GestureDetector(
            onTap: () => scheduleProvider.setSelectedDayIndex(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ?const Color(0xFF044B89): Colors.white  ,

                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                days[index],
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white:Color(0xFF044B89)  ,
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
  Widget _buildScheduleList(ScheduleProvider scheduleProvider) {
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
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: scheduleList.length,
      itemBuilder: (context, index) {
        final scheduleItem = scheduleList[index];
        final randomColor = Color(0xFF044B89); // Generate a random color

        return Card(
          color: Colors.white,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1), // Add a grey border
          ),
          child: ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: randomColor, // Add a light background color to the SVG
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: SvgPicture.asset(
                scheduleItem['icon']!,
                width: 40,
                height: 40,
              ),
            ),
            title: Text(
              scheduleItem['time']!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scheduleItem['class']!, style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),),
                Text(scheduleItem['subject']!, style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),),
              ],
            ),
          ),
        );
      },
    );
  }


}