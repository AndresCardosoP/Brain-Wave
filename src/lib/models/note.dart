// lib/models/note.dart

class Note {
  final int? id; // Auto-incremented by SQLite
  final int? folderId; // For folder associations
  final String title;
  final String content;
  final DateTime timestamp;
  final String? attachmentPath; // For file attachments

  Note({
    this.id,
    this.folderId,
    required this.title,
    required this.content,
    required this.timestamp,
    this.attachmentPath,
  });

  // Convert a Note into a Map for the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'attachmentPath': attachmentPath,
    };
  }

  // Create a Note from a Map (retrieved from the database).
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      folderId: map['folderId'],
      title: map['title'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      attachmentPath: map['attachmentPath'],
    );
  }
}