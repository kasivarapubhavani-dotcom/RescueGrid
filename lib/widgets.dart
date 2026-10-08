import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';

/// Brand colour used by the splash screen, app bars and theme seed.
const brandMaroon = Color(0xFF8E1B24);

/// Soft gradient background used behind every inner page.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.primaryContainer.withAlpha(110), cs.surface],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, this.color, {super.key});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class Stat extends StatelessWidget {
  const Stat(this.label, this.value, {super.key, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ]),
      ),
    );
  }
}

class Bell extends StatelessWidget {
  const Bell({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final mine = store.notes.where((n) => n.to == userId).toList();
        final unread = mine.where((n) => !n.read).length;
        return IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (mine.isEmpty)
                      const ListTile(title: Text('No notifications yet')),
                    for (final n in mine.reversed)
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: Text(n.text),
                        subtitle: Text(hms(n.time)),
                      ),
                  ],
                ),
              ),
            );
            store.markRead(userId);
          },
        );
      },
    );
  }
}
