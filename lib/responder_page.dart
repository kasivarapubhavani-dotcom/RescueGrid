import 'package:flutter/material.dart';
import 'incident_tile.dart';
import 'store.dart';

class ResponderHome extends StatelessWidget {
  const ResponderHome({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.byId(id)!;
        final mine = store.incidents.where((i) => i.responderId == id).toList();
        final active = mine.where((i) => i.active).toList();
        final done = mine.where((i) => !i.active).toList();
        final t = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.badge_outlined),
                title: Text(me.onDuty ? 'On duty' : 'Off duty'),
                subtitle: Text('${me.type}, current workload ${me.workload}'),
                value: me.onDuty,
                onChanged: (v) => store.setDuty(me, v),
              ),
            ),
            const SizedBox(height: 12),
            Text('Active assignments', style: t.titleMedium),
            if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(me.onDuty
                    ? 'No assignments right now. You are visible to dispatch.'
                    : 'You are off duty and will not receive assignments.'),
              ),
            for (final i in active) IncidentTile(i: i),
            if (done.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Completed', style: t.titleMedium),
              for (final i in done) IncidentTile(i: i),
            ],
          ],
        );
      },
    );
  }
}
