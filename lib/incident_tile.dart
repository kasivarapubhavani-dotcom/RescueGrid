import 'package:flutter/material.dart';
import 'incident_page.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class IncidentTile extends StatelessWidget {
  const IncidentTile({super.key, required this.i});
  final Incident i;

  @override
  Widget build(BuildContext context) {
    final s = currentSession;
    final quick = s != null &&
        s.role == Role.responder &&
        i.responderId == s.userId &&
        i.status == Status.assigned;
    return Card(
      child: Column(children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: i.level.color.withAlpha(38),
            child: Icon(i.category.icon, color: i.level.color),
          ),
          title: Text('${i.category.label} at ${i.place.name}'),
          subtitle: Text(
              '#${i.id}  ${i.status.label}${i.needsAttention ? '  (needs attention)' : ''}'),
          trailing: Pill(i.level.label, i.level.color),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => IncidentPage(id: i.id))),
        ),
        if (quick)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: [
              Text('Respond within ${i.acceptSecondsLeft}s or this escalates',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FilledButton(
                      onPressed: () => store.accept(i),
                      child: const Text('Accept')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => store.decline(i),
                      child: const Text('Decline')),
                ),
              ]),
            ]),
          ),
      ]),
    );
  }
}
