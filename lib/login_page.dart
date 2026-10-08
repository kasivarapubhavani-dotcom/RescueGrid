import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.onLogin});
  final ValueChanged<Session> onLogin;

  Future<void> _pickResponder(BuildContext context) async {
    final id = await showDialog<String>(
      context: context,
      builder: (dctx) => SimpleDialog(
        title: const Text('Sign in as responder'),
        children: [
          for (final r in store.responders)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dctx, r.id),
              child: Text('${r.name}  (${r.type})'),
            ),
        ],
      ),
    );
    if (id != null) onLogin(Session(Role.responder, id));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Backdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.warning_amber_rounded, size: 64, color: cs.primary),
                const SizedBox(height: 8),
                Text('RescueGrid',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Report campus emergencies and get the right help fast.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                _RoleTile(
                  icon: Icons.school,
                  title: 'Student',
                  subtitle: 'Report an emergency and track the response',
                  onTap: () => onLogin(Session(Role.student, 'student')),
                ),
                _RoleTile(
                  icon: Icons.local_hospital,
                  title: 'Responder',
                  subtitle: 'Receive assignments and update status',
                  onTap: () => _pickResponder(context),
                ),
                _RoleTile(
                  icon: Icons.dashboard,
                  title: 'Command center',
                  subtitle: 'Monitor incidents and override assignments',
                  onTap: () => onLogin(Session(Role.admin, 'admin')),
                ),
                const SizedBox(height: 16),
                Text('Campus single sign-on is simulated. Choose a role to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
