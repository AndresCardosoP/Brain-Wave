// lib/models/note.dart

class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime timestamp;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  // Convert a Note into a Map. The keys correspond to the column names in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create a Note from a Map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}