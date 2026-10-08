import 'dart:typed_data';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------- domain ----
enum Category { medical, fire, security, accident, harassment, other }

extension CategoryX on Category {
  String get label => switch (this) {
        Category.medical => 'Medical',
        Category.fire => 'Fire',
        Category.security => 'Security',
        Category.accident => 'Accident',
        Category.harassment => 'Harassment',
        Category.other => 'Other',
      };
  IconData get icon => switch (this) {
        Category.medical => Icons.medical_services,
        Category.fire => Icons.local_fire_department,
        Category.security => Icons.shield,
        Category.accident => Icons.directions_car,
        Category.harassment => Icons.report,
        Category.other => Icons.help_outline,
      };
  int get base => switch (this) {
        Category.medical => 45,
        Category.fire => 55,
        Category.security => 40,
        Category.accident => 45,
        Category.harassment => 35,
        Category.other => 15,
      };
  // Which responder skill this category needs.
  String get skill => switch (this) {
        Category.medical => 'medical',
        Category.fire => 'fire',
        Category.security => 'security',
        Category.accident => 'medical',
        Category.harassment => 'security',
        Category.other => 'general',
      };
}

enum Level { low, medium, high, critical }

extension LevelX on Level {
  String get label => switch (this) {
        Level.low => 'Low',
        Level.medium => 'Medium',
        Level.high => 'High',
        Level.critical => 'Critical',
      };
  Color get color => switch (this) {
        Level.low => Colors.green.shade700,
        Level.medium => Colors.amber.shade800,
        Level.high => Colors.deepOrange,
        Level.critical => Colors.red.shade700,
      };
}

enum Status { reported, assigned, enRoute, arrived, resolved, unassigned }

extension StatusX on Status {
  String get label => switch (this) {
        Status.reported => 'Reported',
        Status.assigned => 'Awaiting acceptance',
        Status.enRoute => 'Responder en route',
        Status.arrived => 'On scene',
        Status.resolved => 'Resolved',
        Status.unassigned => 'No responder available',
      };
  Color get color => switch (this) {
        Status.reported => Colors.blueGrey,
        Status.assigned => Colors.orange.shade800,
        Status.enRoute => Colors.blue.shade700,
        Status.arrived => Colors.purple,
        Status.resolved => Colors.green.shade700,
        Status.unassigned => Colors.red.shade700,
      };
}

class Place {
  const Place(this.name, this.x, this.y, this.risk);
  final String name;
  final double x, y; // position on a 0..100 campus grid
  final double risk; // 0..1 location risk used by the severity engine
}

const places = <Place>[
  Place('Main Gate', 50, 92, 0.3),
  Place('Library', 25, 25, 0.1),
  Place('Hostel Block A', 80, 20, 0.5),
  Place('Cafeteria', 55, 50, 0.2),
  Place('Sports Ground', 15, 70, 0.4),
  Place('CSE Block', 45, 12, 0.1),
  Place('Auditorium', 78, 68, 0.2),
];

class Responder {
  Responder(this.id, this.name, this.type, this.skill, this.x, this.y);
  final String id, name, type, skill;
  double x, y;
  bool onDuty = true;
  int workload = 0;
}

class TimelineEvent {
  TimelineEvent(this.time, this.text);
  final DateTime time;
  final String text;
}

class Note {
  Note(this.to, this.text);
  final String to;
  final String text;
  final DateTime time = DateTime.now();
  bool read = false;
}

class Incident {
  Incident({
    required this.id,
    required this.category,
    required this.place,
    required this.people,
    required this.description,
    required this.photo,
    required this.score,
    required this.level,
    required this.breakdown,
  });
  final int id;
  final Category category;
  final Place place;
  final int people;
  final String description;
  final Uint8List? photo; // image bytes picked by the student
  final int score;
  final Level level;
  final List<String> breakdown;
  Status status = Status.reported;
  String? responderId;
  final Set<String> declined = {};
  int acceptSecondsLeft = 0;
  bool backupRequested = false;
  bool needsAttention = false;
  final DateTime createdAt = DateTime.now();
  DateTime? resolvedAt;
  final List<TimelineEvent> timeline = [];
  bool get active => status != Status.resolved;
  bool get hasPhoto => photo != null;
}

enum Role { student, responder, admin }

class Session {
  Session(this.role, this.userId);
  final Role role;
  final String userId; // 'student', 'admin' or a responder id
}

Session? currentSession;

String hms(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
