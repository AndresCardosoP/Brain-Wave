// ai_local_db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AiLocalDbHelper {
  static final AiLocalDbHelper _instance = AiLocalDbHelper._internal();
  factory AiLocalDbHelper() => _instance;
  AiLocalDbHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'ai_features.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ai_data (
        note_id INTEGER PRIMARY KEY,
        summary TEXT,
        suggestions TEXT
      )
    ''');
  }

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

  Future<void> deleteAiData(int noteId) async {
    final db = await database;
    await db.delete(
      'ai_data',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }
}