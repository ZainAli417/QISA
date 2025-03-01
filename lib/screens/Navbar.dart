import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'SessionnStats.dart';
import 'SettingsScreen.dart';
import 'SheduleScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'TeacherScreen.dart';

class navbar extends StatefulWidget {
  @override
  _navbarState createState() => _navbarState();
}

class _navbarState extends State<navbar> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    TeacherScreen(),
    ScheduleScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _children[_currentIndex], // Display the selected screen
      bottomNavigationBar: FloatingNavbar(
        currentIndex: _currentIndex,
        onTabTapped: _onTabTapped,
      ),
    );
  }
}

class FloatingNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  FloatingNavbar({required this.currentIndex, required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Adjusted padding
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.35),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.white,
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              // Removed the grey shading hover effect
              //selectedItemColor: Colors.teal,
              //unselectedItemColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: onTabTapped, // Navigation logic handled externally
              items: [
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    currentIndex == 0
                        ? 'assets/images/home_active_icon.svg'
                        : 'assets/images/home_icon.svg',
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    currentIndex == 1
                        ? 'assets/images/schedule_active.svg'
                        : 'assets/images/schedule.svg',
                  ),
                  label: 'Schedule',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    currentIndex == 2
                        ? 'assets/images/profile_active.svg'
                        : 'assets/images/profile.svg',
                  ),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    currentIndex == 3
                        ? 'assets/images/setting_active.svg'
                        : 'assets/images/setting.svg',
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}