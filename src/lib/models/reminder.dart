// lib/models/reminder.dart

class Reminder {
  final int? id;
  final int noteId;
  final String userId;
  final DateTime reminderTime;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    this.id,
    required this.noteId,
    required this.userId,
    required this.reminderTime,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      userId: map['user_id'] as String,
      reminderTime: DateTime.parse(map['reminder_time'] as String),
      location: map['location'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'user_id': userId,
      'reminder_time': reminderTime.toIso8601String(),
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}