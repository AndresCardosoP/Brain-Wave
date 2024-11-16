// lib/models/reminder.dart

class Reminder {
  final int? id; // Unique identifier for the reminder
  final int noteId; // Identifier for the associated note
  final String userId; // Identifier for the user who created the reminder
  final DateTime reminderTime; // Time when the reminder is set
  final String? location; // Optional location for the reminder
  final DateTime createdAt; // Timestamp when the reminder was created
  final DateTime updatedAt; // Timestamp when the reminder was last updated

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
    // Create a Reminder instance from a map
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
    // Convert a Reminder instance to a map
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