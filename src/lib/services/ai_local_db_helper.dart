import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AiLocalDbHelper {
  // Create a singleton instance of AiLocalDbHelper
  static final AiLocalDbHelper _instance = AiLocalDbHelper._internal();
  factory AiLocalDbHelper() => _instance;
  AiLocalDbHelper._internal();

  Database? _database;

  // Create a getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'ai_features.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the ai_data table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ai_data (
        note_id INTEGER PRIMARY KEY,
        summary TEXT,
        suggestions TEXT
      )
    ''');
  }

  // Insert AI data into the ai_data table
  Future<void> insertAiData(int noteId, String summary, List<String> suggestions) async {
    final db = await database;
    await db.insert(
      'ai_data',
      {
        'note_id': noteId,
        'summary': summary,
        'suggestions': suggestions.join('||'),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get AI data from the ai_data table
  Future<Map<String, dynamic>?> getAiData(int noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_data',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Delete AI data from the ai_data table
  Future<void> deleteAiData(int noteId) async {
    final db = await database;
    await db.delete(
      'ai_data',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }
}