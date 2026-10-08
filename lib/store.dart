import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
//import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'models.dart';

// Holds all state and runs the severity engine, dispatch engine, escalation
// and responder movement. Swap this class for Firebase/WebSocket calls later.
class Store extends ChangeNotifier {
  Store() {
    Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const double speed = 4; // grid units per second (demo speed)
  static const int acceptWindow = 20; // seconds before escalation
  static const int maxWorkload = 2;

  final responders = <Responder>[
    Responder('r1', 'Anita', 'Medic', 'medical', 55, 45),
    Responder('r2', 'Kiran', 'Medic', 'medical', 20, 30),
    Responder('r3', 'Raju', 'Fire marshal', 'fire', 75, 70),
    Responder('r4', 'Sana', 'Security', 'security', 50, 88),
    Responder('r5', 'Imran', 'Security', 'security', 80, 25),
    Responder('r6', 'Meera', 'Hostel warden', 'general', 30, 60),
  ];
  final incidents = <Incident>[];
  final notes = <Note>[];
  int _nextId = 101;

  Responder? byId(String? id) {
    if (id == null) return null;
    for (final r in responders) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ---- severity engine: category + keywords + people + night + location ----
  ({int score, Level level, List<String> parts}) assess(
      Category c, String desc, int people, Place p) {
    final parts = <String>[];
    var s = c.base;
    parts.add('Category ${c.label}: +${c.base}');
    final d = desc.toLowerCase();
    const keys = [
      'unconscious', 'bleeding', 'fire', 'smoke', 'weapon',
      'chest', 'trapped', 'breathing', 'knife', 'followed',
    ];
    final hits = keys.where((k) => d.contains(k)).toList();
    if (hits.isNotEmpty) {
      final add = min(hits.length, 3) * 10;
      s += add;
      parts.add('Keywords (${hits.join(', ')}): +$add');
    }
    final ppl = min(people, 5) * 4;
    s += ppl;
    parts.add('$people affected: +$ppl');
    final h = DateTime.now().hour;
    if (h >= 22 || h < 5) {
      s += 8;
      parts.add('Night time: +8');
    }
    final risk = (p.risk * 10).round();
    s += risk;
    parts.add('Location risk at ${p.name}: +$risk');
    final level = s >= 75
        ? Level.critical
        : s >= 55
            ? Level.high
            : s >= 35
                ? Level.medium
                : Level.low;
    return (score: s, level: level, parts: parts);
  }

  // ---- dispatch engine: skill + ETA + workload (ETA weighs more if severe) ----
  double eta(Responder r, Place p) =>
      sqrt(pow(r.x - p.x, 2) + pow(r.y - p.y, 2)) / speed;

  String etaText(Responder r, Place p) => '${eta(r, p).round()} s';

  List<(Responder, double)> rank(Incident i, {bool manual = false}) {
    final need = i.category.skill;
    final etaW = i.level.index >= Level.high.index ? 40.0 : 30.0;
    final out = <(Responder, double)>[];
    for (final r in responders) {
      if (!r.onDuty) continue;
      if (!manual && (i.declined.contains(r.id) || r.workload >= maxWorkload)) {
        continue;
      }
      final skill = r.skill == need ? 40.0 : (r.skill == 'general' ? 15.0 : 5.0);
      final etaScore =
          etaW * (1 - (eta(r, i.place) / 30).clamp(0.0, 1.0).toDouble());
      final load =
          20.0 * (1 - (r.workload / maxWorkload).clamp(0.0, 1.0).toDouble());
      out.add((r, skill + etaScore + load));
    }
    out.sort((a, b) => b.$2.compareTo(a.$2));
    return out;
  }

  // ---- actions ----
  void _log(Incident i, String text) =>
      i.timeline.add(TimelineEvent(DateTime.now(), text));

  void push(String to, String text) => notes.add(Note(to, text));

  void markRead(String userId) {
    for (final n in notes) {
      if (n.to == userId) n.read = true;
    }
    notifyListeners();
  }

  Incident report(
      Category c, Place p, int people, String desc, Uint8List? photo) {
    final a = assess(c, desc, people, p);
    final i = Incident(
      id: _nextId++,
      category: c,
      place: p,
      people: people,
      description: desc.trim(),
      photo: photo,
      score: a.score,
      level: a.level,
      breakdown: a.parts,
    );
    _log(i, 'Reported by student with GPS fix at ${p.name}');
    _log(i, 'Severity scored ${a.score}: ${a.level.label}');
    incidents.insert(0, i);
    push('admin', 'New ${a.level.label} incident #${i.id}: ${c.label} at ${p.name}');
    _autoAssign(i);
    notifyListeners();
    return i;
  }

  void _release(Incident i) {
    final r = byId(i.responderId);
    if (r != null && r.workload > 0) r.workload--;
  }

  void _autoAssign(Incident i) {
    final ranked = rank(i);
    if (ranked.isEmpty) {
      i.status = Status.unassigned;
      i.responderId = null;
      i.needsAttention = true;
      _log(i, 'No responder available. Command center alerted');
      push('admin', 'Incident #${i.id} has no available responder');
    } else {
      final how = i.declined.isEmpty
          ? 'Auto-assigned'
          : 'Reassigned to next candidate';
      _assignTo(i, ranked.first.$1, '$how (score ${ranked.first.$2.round()})');
    }
  }

  void _assignTo(Incident i, Responder r, String how) {
    i.responderId = r.id;
    i.status = Status.assigned;
    i.acceptSecondsLeft = acceptWindow;
    i.needsAttention = i.backupRequested;
    r.workload++;
    _log(i, '$how: ${r.name}');
    push(r.id, 'New assignment #${i.id}: ${i.category.label} at ${i.place.name}');
  }

  void accept(Incident i) {
    final r = byId(i.responderId);
    if (r == null) return;
    i.status = Status.enRoute;
    _log(i, '${r.name} accepted, ETA ${etaText(r, i.place)}');
    push('student', '${r.name} is on the way to ${i.place.name}');
    push('admin', 'Incident #${i.id} accepted by ${r.name}');
    notifyListeners();
  }

  void decline(Incident i) {
    final r = byId(i.responderId);
    if (r == null) return;
    _release(i);
    i.declined.add(r.id);
    _log(i, '${r.name} declined');
    _autoAssign(i);
    notifyListeners();
  }

  void requestBackup(Incident i) {
    final r = byId(i.responderId);
    i.backupRequested = true;
    i.needsAttention = true;
    _log(i, 'Backup requested by ${r?.name ?? 'responder'}');
    push('admin', 'Backup requested on #${i.id} at ${i.place.name}');
    notifyListeners();
  }

  void resolve(Incident i) {
    final r = byId(i.responderId);
    _release(i);
    i.status = Status.resolved;
    i.resolvedAt = DateTime.now();
    i.needsAttention = false;
    _log(i, 'Resolved by ${r?.name ?? 'responder'}');
    push('student', 'Incident #${i.id} has been resolved');
    push('admin', 'Incident #${i.id} resolved');
    notifyListeners();
  }

  void manualAssign(Incident i, Responder r) {
    _release(i);
    i.declined.remove(r.id);
    _assignTo(i, r, 'Manual override by command center');
    i.needsAttention = false;
    notifyListeners();
  }

  void setDuty(Responder r, bool v) {
    r.onDuty = v;
    notifyListeners();
  }

  void simulateIncident() {
    final rnd = Random();
    const descs = [
      'Student unconscious and bleeding',
      'Smoke coming from the lab',
      'Suspicious person with a knife',
      'Two bikes collided, one trapped',
      'Feeling unsafe, being followed',
      'Minor fall, ankle pain',
    ];
    report(
      Category.values[rnd.nextInt(Category.values.length)],
      places[rnd.nextInt(places.length)],
      1 + rnd.nextInt(3),
      descs[rnd.nextInt(descs.length)],
      null,
    );
  }

  // ---- real-time loop: escalation + responder movement ----
  void _tick() {
    var changed = false;
    for (final i in incidents) {
      if (i.status == Status.assigned) {
        i.acceptSecondsLeft--;
        changed = true;
        if (i.acceptSecondsLeft <= 0) {
          final r = byId(i.responderId);
          _release(i);
          if (r != null) i.declined.add(r.id);
          _log(i, 'Escalated: ${r?.name ?? 'responder'} did not respond in ${acceptWindow}s');
          push('admin', 'Incident #${i.id} escalated to next candidate');
          _autoAssign(i);
        }
      } else if (i.status == Status.enRoute) {
        final r = byId(i.responderId);
        if (r == null) continue;
        final dx = i.place.x - r.x, dy = i.place.y - r.y;
        final d = sqrt(dx * dx + dy * dy);
        if (d <= speed) {
          r.x = i.place.x;
          r.y = i.place.y;
          i.status = Status.arrived;
          _log(i, '${r.name} arrived on scene');
          push('student', '${r.name} has arrived at ${i.place.name}');
          push('admin', 'Incident #${i.id}: responder on scene');
        } else {
          r.x += dx / d * speed;
          r.y += dy / d * speed;
        }
        changed = true;
      } else if (i.status == Status.unassigned) {
        final ranked = rank(i);
        if (ranked.isNotEmpty) {
          _assignTo(i, ranked.first.$1, 'Responder became available');
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }
}

final store = Store();
