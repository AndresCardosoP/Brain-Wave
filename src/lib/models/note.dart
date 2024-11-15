// lib/models/note.dart

class Note {
  final int? id; // Nullable for new notes
  final String title;
  final String body;
  final String userId;
  final int? folderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool hasReminder; // Changed from 'final' to mutable

  Note({
    this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.folderId,
    this.createdAt,
    this.updatedAt,
    this.hasReminder = false, // Provide default value
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      userId: map['user_id'] as String,
      folderId: map['folder_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      hasReminder: map['has_reminder'] as bool? ?? false, // Include hasReminder
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'body': body,
      'user_id': userId,
      'folder_id': folderId,
      'updated_at': updatedAt?.toIso8601String(),
      'has_reminder': hasReminder, // Add hasReminder to the map
    };
    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    return map;
  }
}