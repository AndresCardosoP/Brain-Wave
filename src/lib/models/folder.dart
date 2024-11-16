// Define the Folder class
class Folder {
  // Declare the properties of the Folder class
  final int id;
  final String name;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor for the Folder class
  Folder({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Folder instance from a map
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int,
      name: map['name'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Method to convert a Folder instance to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}