import 'package:flutter/material.dart';
import 'campus_map.dart';
import 'incident_tile.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.incidents;
        final active = all.where((i) => i.active).toList();
        final resolved = all.where((i) => !i.active).toList();
        final attention = active
            .where((i) => i.needsAttention || i.status == Status.unassigned)
            .toList();
        final avg = resolved.isEmpty
            ? '-'
            : '${(resolved.fold<int>(0, (a, i) => a + i.resolvedAt!.difference(i.createdAt).inSeconds) / resolved.length).round()}s';
        final shown = switch (filter) {
          'Active' => active,
          'Needs attention' => attention,
          'Resolved' => resolved,
          _ => all,
        };
        final t = Theme.of(context).textTheme;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: store.simulateIncident,
            icon: const Icon(Icons.bolt),
            label: const Text('Simulate incident'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Row(children: [
                Expanded(child: Stat('Active', '${active.length}')),
                Expanded(
                  child: Stat('Need attention', '${attention.length}',
                      color: attention.isEmpty ? null : Colors.red.shade700),
                ),
                Expanded(child: Stat('Resolved', '${resolved.length}')),
                Expanded(child: Stat('Avg resolve', avg)),
              ]),
              const SizedBox(height: 8),
              CampusMap(incidents: active),
              const SizedBox(height: 16),
              Text('Responders', style: t.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in store.responders)
                  Chip(
                    avatar: Icon(Icons.circle,
                        size: 12, color: r.onDuty ? Colors.green : Colors.grey),
                    label: Text('${r.name}, ${r.type}, load ${r.workload}'),
                  ),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                for (final f in ['All', 'Active', 'Needs attention', 'Resolved'])
                  ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f),
                  ),
              ]),
              const SizedBox(height: 8),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No incidents here. Tap Simulate incident to test the flow.'),
                ),
              for (final i in shown) IncidentTile(i: i),
            ],
          ),
        );
      },
    );
  }
}
