import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/breakpoint.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:videosdk_flutter_example/providers/principal_provider.dart';
import 'package:videosdk_flutter_example/providers/profile_provider.dart';
import 'package:videosdk_flutter_example/providers/role_provider.dart';
import 'package:videosdk_flutter_example/providers/shedule_provider.dart';
import 'package:videosdk_flutter_example/providers/splash_provider.dart';
import 'package:videosdk_flutter_example/providers/teacher_provider.dart';
import 'package:videosdk_flutter_example/providers/topic_provider.dart';
import 'package:videosdk_flutter_example/screens/SplashScreen.dart';
import 'package:videosdk_flutter_example/screens/TeacherScreen.dart';
import 'package:videosdk_flutter_example/screens/conference-call/conference_meeting_screen.dart';
import 'package:window_manager/window_manager.dart';

import 'constants/colors.dart';
import 'firebase_options.dart';
import 'navigator_key.dart';


void main() async {
  // Run Flutter App
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 700),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.setResizable(false);
    windowManager.setMaximizable(false);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Material App
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => PrincipalProvider()),
        ChangeNotifierProvider(create: (_) => CreateTopicProvider()),

        ChangeNotifierProvider(create: (_) => RoleProvider()),

 ],
      child: MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
        title: 'QISA',
        theme: ThemeData.light().copyWith(
          appBarTheme: const AppBarTheme().copyWith(
            color: primaryColor,
          ),
          primaryColor: primaryColor,
          scaffoldBackgroundColor: secondaryColor,
        ),
        home: SplashScreen(),
        routes: {
          '/home': (context) => TeacherScreen(),
        },
        navigatorKey: navigatorKey,
      ),
    );
  }
}
