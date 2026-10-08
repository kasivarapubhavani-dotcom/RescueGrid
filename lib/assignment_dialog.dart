import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

/// Shown automatically to a responder when dispatch assigns them an incident.
/// Pops with: true = accepted, false = declined, null = no longer theirs
/// (timed out and escalated, or reassigned by the command center).
class AssignmentDialog extends StatefulWidget {
  const AssignmentDialog({
    super.key,
    required this.incidentId,
    required this.responderId,
  });
  final int incidentId;
  final String responderId;

  @override
  State<AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<AssignmentDialog> {
  bool _closed = false;

  void _close(bool? result) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final i = store.incidents.firstWhere((x) => x.id == widget.incidentId);
        final stillMine = i.responderId == widget.responderId &&
            i.status == Status.assigned;
        if (!stillMine && !_closed) {
          // Timed out or reassigned: close this pop-up.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _close(null);
          });
        }
        final r = store.byId(widget.responderId);
        final t = Theme.of(context).textTheme;
        return AlertDialog(
          icon: Icon(Icons.notifications_active, color: i.level.color, size: 36),
          title: const Text('New emergency assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill('${i.level.label} severity', i.level.color),
                const SizedBox(height: 12),
                Text('${i.category.label} at ${i.place.name}',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (i.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(i.description),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${i.people} affected${r == null ? '' : ', your ETA ${store.etaText(r, i.place)}'}',
                  style: t.bodySmall,
                ),
                if (i.photo != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      i.photo!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Respond within ${i.acceptSecondsLeft}s or this escalates',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (i.acceptSecondsLeft / Store.acceptWindow)
                      .clamp(0.0, 1.0)
                      .toDouble(),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                store.decline(i);
                _close(false);
              },
              icon: const Icon(Icons.close),
              label: const Text('Decline'),
            ),
            FilledButton.icon(
              onPressed: () {
                store.accept(i);
                _close(true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }
}
