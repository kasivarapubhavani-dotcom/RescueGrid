import 'package:flutter/material.dart';
import 'campus_map.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class IncidentPage extends StatelessWidget {
  const IncidentPage({super.key, required this.id});
  final int id;

  List<Widget> _actions(BuildContext context, Incident i) {
    final s = currentSession;
    if (s == null || !i.active) return [];
    final mine = s.role == Role.responder && i.responderId == s.userId;
    final out = <Widget>[];
    if (mine && i.status == Status.assigned) {
      out.add(Text('Respond within ${i.acceptSecondsLeft}s or this escalates',
          style: const TextStyle(fontWeight: FontWeight.w600)));
      out.add(Row(children: [
        Expanded(
          child: FilledButton(
              onPressed: () => store.accept(i), child: const Text('Accept')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
              onPressed: () => store.decline(i), child: const Text('Decline')),
        ),
      ]));
    }
    if (mine && i.status == Status.arrived) {
      out.add(FilledButton.icon(
        onPressed: () => store.resolve(i),
        icon: const Icon(Icons.check),
        label: const Text('Mark resolved'),
      ));
    }
    if (mine &&
        (i.status == Status.enRoute || i.status == Status.arrived) &&
        !i.backupRequested) {
      out.add(OutlinedButton.icon(
        onPressed: () => store.requestBackup(i),
        icon: const Icon(Icons.group_add),
        label: const Text('Request backup'),
      ));
    }
    if (s.role == Role.admin) {
      out.add(OutlinedButton.icon(
        onPressed: () => _reassign(context, i),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Manual assignment override'),
      ));
    }
    return [
      for (final w in out)
        Padding(padding: const EdgeInsets.only(top: 8), child: w),
    ];
  }

  Future<void> _reassign(BuildContext context, Incident i) async {
    final ranked = store.rank(i, manual: true);
    final picked = await showDialog<Responder>(
      context: context,
      builder: (dctx) => SimpleDialog(
        title: const Text('Assign responder (best match first)'),
        children: [
          if (ranked.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No on-duty responders.'),
            ),
          for (final e in ranked)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dctx, e.$1),
              child: Text(
                  '${e.$1.name}  score ${e.$2.round()}  ETA ${store.etaText(e.$1, i.place)}'),
            ),
        ],
      ),
    );
    if (picked != null) store.manualAssign(i, picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final i = store.incidents.firstWhere((x) => x.id == id);
        final r = store.byId(i.responderId);
        final t = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(title: Text('Incident #${i.id}')),
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
                    Text(
                        '${i.people} affected${i.hasPhoto ? ', photo attached' : ''}',
                        style: t.bodySmall),
                    if (i.photo != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          i.photo!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    CampusMap(incidents: [i]),
                    if (r != null && i.active)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${r.name}, ${r.type}'),
                        subtitle: Text(i.status == Status.enRoute
                            ? 'ETA ${store.etaText(r, i.place)}'
                            : i.status.label),
                      ),
                    ..._actions(context, i),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('Why ${i.level.label}? Score ${i.score}'),
                      children: [
                        for (final p in i.breakdown)
                          ListTile(dense: true, title: Text(p)),
                      ],
                    ),
                    const SizedBox(height: 8),
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
