// lib/models/note.dart

class Note {
  final int? id; // Nullable for new notes
  final String title;
  final String body;
  final String userId;
  final int? folderId;
  final String? attachmentPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.folderId,
    this.attachmentPath,
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      userId: map['user_id'] as String,
      folderId: map['folder_id'] as int?,
      attachmentPath: map['attachment_path'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'body': body,
      'user_id': userId,
      'folder_id': folderId,
      'attachment_path': attachmentPath,
      'updated_at': updatedAt?.toIso8601String(),
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