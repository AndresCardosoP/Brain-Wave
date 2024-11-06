// lib/services/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/folder.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('brainwave.db');
    return _database!;
  }

  Future<Database> _initDB(String filename) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filename);

    return await openDatabase(
      path,
      version: 2, // Ensure this matches your migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Added onUpgrade callback
    );
  }

  // Create tables when the database is first created
  Future _createDB(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Create notes table with folderId as a foreign key
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folderId INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        attachmentPath TEXT,
        FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');
  }

  // Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add folderId column to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN folderId INTEGER;');

      // Add attachmentPath column to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN attachmentPath TEXT;');

      // Note: SQLite does not support adding foreign key constraints using ALTER TABLE
      // The FOREIGN KEY constraint on folderId won't be added in the existing table
    }
    // Future migrations can be handled here
  }

  // Notes CRUD operations

  // Insert a new note into the database
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  // Retrieve notes from the database, optionally by folderId
  Future<List<Note>> getNotes({int? folderId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (folderId != null) {
      maps = await db.query(
        'notes',
        where: 'folderId = ?',
        whereArgs: [folderId],
        orderBy: 'timestamp DESC',
      );
    } else {
      maps = await db.query(
        'notes',
        where: 'folderId IS NULL',
        orderBy: 'timestamp DESC',
      );
    }

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // Update an existing note in the database
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Delete a note from the database
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Folders CRUD operations

  // Insert a new folder into the database
  Future<int> insertFolder(Folder folder) async {
    final db = await database;
    return await db.insert('folders', folder.toMap());
  }

  // Retrieve all folders from the database
  Future<List<Folder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  // Delete a folder from the database
  Future<int> deleteFolder(int id) async {
    final db = await database;
    // Set folderId to null for notes in this folder
    await db.update(
      'notes',
      {'folderId': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}