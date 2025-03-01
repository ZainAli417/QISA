import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      begin: Offset(0, 0),
      end: const Offset(0, -0.5), // Adjust as needed
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut), // First 60%
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _slideAnimationLogo,
                child: FadeTransition(
                  opacity: _fadeAnimationLogo,
                  child: Center(
                    child: ClipPath(
                      child: Image.asset(
                        'assets/logo.png', // Path to your PNG asset
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover, // Ensure the image scales properly within the circle
                      ),
                    ),

                  ),
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimationButtons,
                child: Column(
                  children: [
                     Text(
                      'Choose Your Role',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
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
                    const SizedBox(height: 20),

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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context, String role, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          role,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
