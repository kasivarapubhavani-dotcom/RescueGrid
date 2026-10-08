import 'package:flutter/material.dart';
import 'login_page.dart';
import 'models.dart';
import 'shell.dart';
import 'splash_page.dart';
import 'widgets.dart';

// ============================================================================
// RescueGrid: campus emergency reporting and response (contest build)
//
// Screen flow:  SplashPage (Campus Safety)  ->  LoginPage  ->  Shell
//
// Files:
//   models.dart         enums, data classes, places, session
//   store.dart          severity engine, dispatch engine, escalation, live loop
//   widgets.dart        brand colour, Backdrop, Pill, Stat, notification Bell
//   campus_map.dart     campus map widget and painter
//   incident_tile.dart  incident list tile
//   incident_page.dart  incident detail, actions, timeline
//   splash_page.dart    first page (landing screen)
//   login_page.dart     second page (role selection)
//   shell.dart          app bar, push banners, role-based body
//   student_pages.dart  student home and report form with photo picker
//   responder_page.dart responder home
//   admin_page.dart     command center
// ============================================================================

void main() => runApp(const RescueGridApp());

class RescueGridApp extends StatelessWidget {
  const RescueGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bar = AppBarTheme(
      backgroundColor: brandMaroon,
      foregroundColor: Colors.white,
    );
    return MaterialApp(
      title: 'RescueGrid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brandMaroon,
        appBarTheme: bar,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brandMaroon,
        brightness: Brightness.dark,
        appBarTheme: bar,
      ),
      home: const Root(),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _started = false; // has the user passed the landing page?

  @override
  Widget build(BuildContext context) {
    final s = currentSession;
    final Widget page;
    if (!_started) {
      page = SplashPage(
        key: const ValueKey('splash'),
        onStart: () => setState(() => _started = true),
      );
    } else if (s == null) {
      page = LoginPage(
        key: const ValueKey('login'),
        onLogin: (x) => setState(() => currentSession = x),
      );
    } else {
      page = Shell(
        key: ValueKey(s.userId),
        session: s,
        onLogout: () => setState(() => currentSession = null),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: page,
    );
  }
}
