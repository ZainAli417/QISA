import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/role_provider.dart';
import 'TeacherScreen.dart';
import 'package:videosdk_flutter_example/screens/common/join_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimationLogo;
  late Animation<Offset> _slideAnimationLogo;
  late Animation<double> _fadeAnimationButtons;

  // Role data map with colors and icons
  final Map<String, Map<String, dynamic>> roleData = {
    'Coordinator/HOD': {
      'color': Colors.purple,
      'icon': Icons.admin_panel_settings,
    },
    'Teacher/Instructor': {
      'color': Colors.green,
      'icon': Icons.book,
    },
    'Students': {
      'color': Colors.orange,
      'icon': Icons.school,
    },
    'Visitors': {
      'color': Colors.indigo,
      'icon': Icons.person,
    },
  };

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Logo Slide Animation
    _slideAnimationLogo = Tween<Offset>(
      begin: const Offset(0,0.5),
      end: const Offset(0, -0.2), // Slide up slightly
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut), // First 60%
    ));

    // Logo Fade Animation
    _fadeAnimationLogo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut), // First 60%
    );

    // Buttons Fade Animation
    _fadeAnimationButtons = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut), // Last 40%
    );

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Option for gradient: LinearGradient
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _slideAnimationLogo,
                  child: FadeTransition(
                    opacity: _fadeAnimationLogo,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20), // Circular logo
                        child: Image.asset(
                          'assets/logo.png', // Ensure this path is correct
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fadeAnimationButtons,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        Text(
                          'Choose Your Role',
                          style: GoogleFonts.poppins(
                            fontSize: 24, // Larger for prominence
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 32), // Increased spacing
                        _buildRoleButton(
                          context,
                          'Coordinator/HOD',
                              () {
                            Provider.of<RoleProvider>(context, listen: false)
                                .setRole('Principal');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TeacherScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16), // Increased spacing
                        _buildRoleButton(
                          context,
                          'Teacher/Instructor',
                              () {
                            Provider.of<RoleProvider>(context, listen: false)
                                .setRole('Teacher');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const JoinScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRoleButton(
                          context,
                          'Students',
                              () {
                            Provider.of<RoleProvider>(context, listen: false)
                                .setRole('Student');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const JoinScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRoleButton(
                          context,
                          'Visitors',
                              () {
                            Provider.of<RoleProvider>(context, listen: false)
                                .setRole('Student');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const JoinScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context, String role, VoidCallback onPressed) {
    final roleInfo = roleData[role]!;
    return Container(
      width: double.infinity, // Full-width button
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: roleInfo['color'], // Role-specific color
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Slightly larger radius
          ),
          elevation: 4, // Subtle shadow for depth
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              roleInfo['icon'],
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10), // Space between icon and text
            Text(
              role,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white, // White text for contrast
              ),
            ),
          ],
        ),
      ),
    );
  }
}