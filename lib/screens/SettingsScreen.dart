import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';


class SettingsScreen extends StatefulWidget {

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final List<Map<String, String>> settingsItems = [
    {"icon": "translate", "title": "English", "route": "/english"},
    {
      "icon": "password",
      "title": "Change password",
      "route": "/changepassword"
    },
    {
      "icon": "privacy_tip",
      "title": "Privacy Policy",
      "url": "https://institute.zbmtech.com/"
    },
    {
      "icon": "description",
      "title": "Terms & Condition",
      "url": "https://institute.zbmtech.com/"
    },
    {"icon": "info", "title": "About Us", "url": "https://institute.zbmtech.com/"},
    {
      "icon": "contact_support",
      "title": "Contact us",
      "url": "https://institute.zbmtech.com/"
    },
    {"icon": "star", "title": "Rate Us", "url": "https://institute.zbmtech.com/"},
    {"icon": "share", "title": "Share", "url": "https://institute.zbmtech.com/"},
  ];

  @override
  void initState() {
    super.initState();

    _addItems();
  }

  void _addItems() async {
    for (int i = 0; i < settingsItems.length; i++) {
      await Future.delayed(Duration(milliseconds: 150));

      _listKey.currentState?.insertItem(i);
    }
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
              'assets/images/back_icon.svg',
              color: Color(0xFF044B89),
            ),
            onPressed: () {},
          ),
          backgroundColor: const Color(0xFF044B89),
          title: Text(
            "Settings",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
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
          Expanded(child: _buildSettingsList()),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemBuilder: (context, index, animation) {
        return _buildSettingsListItem(settingsItems[index], animation);
      },
    );
  }

  Widget _buildSettingsListItem(
      Map<String, String> item, Animation<double> animation) {
    IconData iconData;

    switch (item['icon']) {
      case 'translate':
        iconData = Icons.translate;

        break;

      case 'password':
        iconData = Icons.password;

        break;

      case 'privacy_tip':
        iconData = Icons.privacy_tip;

        break;

      case 'description':
        iconData = Icons.description;

        break;

      case 'info':
        iconData = Icons.info;

        break;

      case 'contact_support':
        iconData = Icons.contact_support;

        break;

      case 'star':
        iconData = Icons.star;

        break;

      case 'share':
        iconData = Icons.share;

        break;

      default:
        iconData = Icons.help; // Fallback icon
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: GestureDetector(
        onTap: () async {
          if (item.containsKey("route")) {
            Navigator.pushNamed(context, item["route"]!);
          } else if (item.containsKey("url")) {
            await launchUrl(Uri.parse(item["url"]!));
          }
        },
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF044B89), // Blue circular background
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    iconData,
                    color:
                        Colors.white, // Ensure the icon is white for visibility
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  item['title']!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black, // Text color changed to black
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black87),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            ),
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
            label: Text(
              "Logout",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => SplashScreen()));
            },
          ),
          const SizedBox(height: 8),
          Text(
            "App Version 1.1.1 Zain Ali",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
