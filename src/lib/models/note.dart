// lib/models/note.dart

class Note {
  final int? id;
  final int? folderId;
  final String title;
  final String content;
  final String timestamp;

  Note({
    this.id,
    this.folderId,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      folderId: map['folderId'],
      title: map['title'],
      content: map['content'],
      timestamp: map['timestamp'],
    );
  }
}