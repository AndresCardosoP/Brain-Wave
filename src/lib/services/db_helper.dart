// src/lib/services/db_helper.dart

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

    // Insert the default "Notes" folder
    await db.insert('folders', {'name': 'Notes'});

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add folderId column to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN folderId INTEGER;');
      // Add attachmentPath column to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN attachmentPath TEXT;');
      // Insert the default "Notes" folder if it doesn't exist
      await db.insert(
        'folders',
        {'name': 'Notes'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    // Future migrations can be handled here
  }

  // Notes CRUD operations

  // Insert a new note into the database
  Future<int> insertNote(Note note) async {
    final db = await database;
    // If no folder is selected, assign to "Notes"
    int folderId = note.folderId ?? await getDefaultFolderId();
    Note noteToInsert = Note(
      folderId: folderId,
      title: note.title,
      content: note.content,
      timestamp: note.timestamp,
      attachmentPath: note.attachmentPath,
    );
    return await db.insert('notes', noteToInsert.toMap());
  }

  // Retrieve all notes from the database
  Future<List<Note>> getNotes({int? folderId}) async {
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
        where: 'folderId IS NULL',
      );
    }
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // Update an existing note
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Delete a note
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
    return await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Retrieve all folders from the database
  Future<List<Folder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  // Get the ID of the default "Notes" folder
  Future<int> getDefaultFolderId() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'name = ?',
      whereArgs: ['Notes'],
    );
    if (maps.isNotEmpty) {
      return maps.first['id'];
    } else {
      // If "Notes" folder doesn't exist, create it
      return await insertFolder(Folder(name: 'Notes'));
    }
  }

  // Update a folder's name
  Future<int> updateFolder(Folder folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  // Delete a folder from the database
  Future<int> deleteFolder(int id) async {
    final db = await database;
    // Prevent deleting the default "Notes" folder
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'id = ? AND name = ?',
      whereArgs: [id, 'Notes'],
    );
    if (maps.isNotEmpty) {
      // Do not allow deletion of "Notes" folder
      return 0;
    }

    // Assign notes to "Notes" folder instead of setting to null
    int defaultFolderId = await getDefaultFolderId();
    await db.update(
      'notes',
      {'folderId': defaultFolderId},
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