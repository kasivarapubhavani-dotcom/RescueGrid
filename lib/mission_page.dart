import 'package:flutter/material.dart';
import 'campus_map.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

/// Opens after a responder accepts an incident. Shows live progress and the
/// two actions a responder needs: "Problem solved" and "I need backup".
class MissionPage extends StatelessWidget {
  const MissionPage({super.key, required this.id});
  final int id;

  Widget _statusCard(BuildContext context, Incident i, Responder? r, bool mine) {
    IconData icon;
    String title;
    String body;
    Color color;
    if (i.status == Status.resolved) {
      icon = Icons.check_circle;
      title = 'Incident resolved';
      body = 'Well done. The student and command center have been notified.';
      color = Colors.green;
    } else if (!mine) {
      icon = Icons.swap_horiz;
      title = 'Incident reassigned';
      body = 'The command center assigned this incident to someone else.';
      color = Colors.orange;
    } else if (i.status == Status.enRoute) {
      icon = Icons.directions_run;
      title = 'You are on your way';
      body = r == null ? '' : 'ETA ${store.etaText(r, i.place)} to ${i.place.name}';
      color = Colors.blue;
    } else if (i.status == Status.arrived) {
      icon = Icons.place;
      title = 'You are on scene';
      body = 'Help the student, then update the status below.';
      color = Colors.purpleAccent;
    } else {
      icon = Icons.hourglass_top;
      title = i.status.label;
      body = '';
      color = Colors.grey;
    }
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(50),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: body.isEmpty ? null : Text(body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final i = store.incidents.firstWhere((x) => x.id == id);
        final r = store.byId(i.responderId);
        final mine = i.responderId == currentSession?.userId;
        final t = Theme.of(context).textTheme;
        final arrived = i.status == Status.arrived;
        final enRoute = i.status == Status.enRoute;
        final canAct = mine && (arrived || enRoute);
        final finished = i.status == Status.resolved || !mine;

        return Scaffold(
          appBar: AppBar(title: Text('Mission: incident #${i.id}')),
          body: Backdrop(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      Pill('${i.level.label} severity', i.level.color),
                      const SizedBox(width: 8),
                      Pill(i.status.label, i.status.color),
                    ]),
                    const SizedBox(height: 12),
                    Text('${i.category.label} at ${i.place.name}',
                        style: t.titleLarge),
                    if (i.description.isNotEmpty) Text(i.description),
                    Text('${i.people} affected', style: t.bodySmall),
                    if (i.photo != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          i.photo!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _statusCard(context, i, r, mine),
                    CampusMap(incidents: [i]),
                    const SizedBox(height: 16),
                    if (canAct) ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        onPressed: arrived ? () => store.resolve(i) : null,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Problem solved'),
                      ),
                      if (enRoute)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'This button turns on when you reach the scene.',
                            textAlign: TextAlign.center,
                            style: t.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        onPressed: i.backupRequested
                            ? null
                            : () => store.requestBackup(i),
                        icon: Icon(
                            i.backupRequested ? Icons.check : Icons.group_add),
                        label: Text(i.backupRequested
                            ? 'Backup requested'
                            : 'I need backup'),
                      ),
                    ],
                    if (finished)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                        icon: const Icon(Icons.home),
                        label: const Text('Back to dashboard'),
                      ),
                    const SizedBox(height: 20),
                    Text('Timeline', style: t.titleMedium),
                    for (final e in i.timeline)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.circle, size: 10),
                        title: Text(e.text),
                        trailing: Text(hms(e.time), style: t.bodySmall),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
