import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';

class CampusMap extends StatelessWidget {
  const CampusMap({super.key, required this.incidents});
  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: CustomPaint(
          size: Size.infinite,
          painter: MapPainter(
            responders: store.responders,
            incidents: incidents,
            ink: cs.onSurface,
            bg: cs.primary.withAlpha(18),
            accent: cs.primary,
          ),
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  MapPainter({
    required this.responders,
    required this.incidents,
    required this.ink,
    required this.bg,
    required this.accent,
  });
  final List<Responder> responders;
  final List<Incident> incidents;
  final Color ink, bg, accent;

  void _label(Canvas c, String t, Offset at, {Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(fontSize: 10, color: color ?? ink.withAlpha(170))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at);
  }

  Responder? _find(String? id) {
    if (id == null) return null;
    for (final r in responders) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Offset o(double x, double y) =>
        Offset(x / 100 * size.width, y / 100 * size.height);
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    final grid = Paint()
      ..color = ink.withAlpha(18)
      ..strokeWidth = 1;
    for (var k = 1; k < 10; k++) {
      final gx = size.width * k / 10;
      final gy = size.height * k / 10;
      canvas.drawLine(Offset(gx, 0), Offset(gx, size.height), grid);
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), grid);
    }

    for (final p in places) {
      canvas.drawCircle(o(p.x, p.y), 4, Paint()..color = ink.withAlpha(90));
      _label(canvas, p.name, o(p.x, p.y) + const Offset(6, -6));
    }

    // Route lines from the assigned responder to the incident.
    for (final i in incidents) {
      final r = _find(i.responderId);
      if (r != null && i.active && i.status != Status.unassigned) {
        canvas.drawLine(
          o(r.x, r.y),
          o(i.place.x, i.place.y),
          Paint()
            ..color = accent
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Responders (blue). Bigger when assigned to a shown incident.
    final busy = incidents.map((i) => i.responderId).toSet();
    for (final r in responders) {
      if (!r.onDuty) continue;
      final big = busy.contains(r.id);
      final c = o(r.x, r.y);
      canvas.drawCircle(c, big ? 8 : 5, Paint()..color = Colors.blue.shade700);
      canvas.drawCircle(
        c,
        big ? 8 : 5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _label(canvas, r.name, c + const Offset(9, 2), color: Colors.blue.shade700);
    }

    // Incidents (severity colour with a halo).
    for (final i in incidents) {
      final c = o(i.place.x, i.place.y);
      canvas.drawCircle(c, 15, Paint()..color = i.level.color.withAlpha(60));
      canvas.drawCircle(c, 7, Paint()..color = i.level.color);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
