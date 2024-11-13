// lib/services/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/folder.dart';
import 'supabase_service.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;
  final SupabaseService _supabaseService = SupabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the database
    _database = await _initDB('brainwave.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2, // Increment version for schema changes
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folderId INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Remove attachmentPath column if it exists
      // Since SQLite doesn't support DROP COLUMN, you might need to recreate the table
      // For simplicity, assuming it's already removed
    }
    // Future migrations can be handled here
  }

  // ------------------- SQLite CRUD Operations -------------------

  // Insert a new note into the SQLite database
  Future<int> insertLocalNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieve all notes from the SQLite database
  Future<List<Note>> getLocalNotes({int? folderId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (folderId != null) {
      maps = await db.query(
        'notes',
        where: 'folderId = ?',
        whereArgs: [folderId],
      );
    } else {
      maps = await db.query(
        'notes',
        orderBy: 'timestamp DESC',
      );
    }
    return List<Note>.from(
      maps.map((note) => Note.fromMap(note)),
    );
  }

  // Update a note in the SQLite database
  Future<int> updateLocalNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Delete a note from the SQLite database
  Future<int> deleteLocalNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insert a new folder into the SQLite database
  Future<int> insertLocalFolder(Folder folder) async {
    final db = await database;
    return await db.insert('folders', folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieve all folders from the SQLite database
  Future<List<Folder>> getLocalFolders() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'folders',
      orderBy: 'name ASC',
    );
    return List<Folder>.from(
      maps.map((folder) => Folder.fromMap(folder)),
    );
  }

  // Update a folder in the SQLite database
  Future<int> updateLocalFolder(Folder folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  // Delete a folder from the SQLite database
  Future<int> deleteLocalFolder(int id) async {
    final db = await database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------- Supabase CRUD Operations -------------------

  // Insert a new note into Supabase
  Future<void> insertCloudNote(Note note, String userId) async {
    await _supabaseService.insertNote(note, userId);
  }

  // Retrieve all notes from Supabase
  Future<List<Note>> getCloudNotes(String userId, {int? folderId}) async {
    return await _supabaseService.getNotes(userId, folderId: folderId);
  }

  // Update a note in Supabase
  Future<void> updateCloudNote(Note note, String userId) async {
    await _supabaseService.updateNote(note, userId);
  }

  // Delete a note from Supabase
  Future<void> deleteCloudNote(int id, String userId) async {
    await _supabaseService.deleteNote(id, userId);
  }

  // Insert a new folder into Supabase
  Future<void> insertCloudFolder(Folder folder, String userId) async {
    await _supabaseService.insertFolder(folder, userId);
  }

  // Retrieve all folders from Supabase
  Future<List<Folder>> getCloudFolders(String userId) async {
    return await _supabaseService.getFolders(userId);
  }

  // Update a folder in Supabase
  Future<void> updateCloudFolder(Folder folder, String userId) async {
    await _supabaseService.updateFolder(folder, userId);
  }

  // Delete a folder from Supabase
  Future<void> deleteCloudFolder(int id, String userId) async {
    await _supabaseService.deleteFolder(id, userId);
  }

  // You can add synchronization methods here to sync local and cloud data
}