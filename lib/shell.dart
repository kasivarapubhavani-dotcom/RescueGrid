import 'package:flutter/material.dart';
import 'admin_page.dart';
import 'models.dart';
import 'responder_page.dart';
import 'store.dart';
import 'student_pages.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.session, required this.onLogout});
  final Session session;
  final VoidCallback onLogout;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _seen = 0;

  @override
  void initState() {
    super.initState();
    _seen = store.notes.length;
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  // Simulated push notification: a floating banner for new notes.
  void _onStore() {
    if (!mounted) return;
    while (_seen < store.notes.length) {
      final n = store.notes[_seen++];
      if (n.to == widget.session.userId) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(n.text),
            behavior: SnackBarBehavior.floating,
          ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final title = switch (s.role) {
      Role.student => 'RescueGrid',
      Role.responder => 'Responder: ${store.byId(s.userId)?.name ?? ''}',
      Role.admin => 'Command center',
    };
    final body = switch (s.role) {
      Role.student => const StudentHome(),
      Role.responder => ResponderHome(id: s.userId),
      Role.admin => const AdminHome(),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Bell(userId: s.userId),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Backdrop(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: body,
          ),
        ),
      ),
    );
  }
}
