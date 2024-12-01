import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../models/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'notification_service.dart';

class DBHelper {
  final NotificationService _notificationService = NotificationService();

  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper.instance() => _instance;
  DBHelper._internal();

  final supabase = Supabase.instance.client;

  // SQLite Database instance
  static Database? _sqliteDatabase;

  // Initialize SQLite Database
  Future<Database> get sqliteDatabase async {
    if (_sqliteDatabase != null) return _sqliteDatabase!;

    // Platform-specific initialization
    if (kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      databaseFactory = databaseFactoryFfi; // Use sqflite_common_ffi for web and desktop
    }

    _sqliteDatabase = await _initSQLiteDB();
    return _sqliteDatabase!;
  }

  Future<Database> _initSQLiteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'brainwave.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment the version number
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE credentials (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          password TEXT NOT NULL
        )
      ''');
      print('Credentials table created.');
    } catch (e) {
      print('Error creating credentials table: $e');
    }

    // Create other tables if necessary
    // Example:
    // await db.execute('CREATE TABLE notes (...)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS credentials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            password TEXT NOT NULL
          )
        ''');
        print('Credentials table upgraded/created.');
      } catch (e) {
        print('Error upgrading/creating credentials table: $e');
      }
    }
    // Handle further migrations if needed
  }

  // ********** Notes CRUD Operations **********

  Future<Note> insertNote(Note note) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase.from('notes').insert({
        'title': note.title,
        'body': note.body,
        'user_id': user.id,
        'folder_id': note.folderId,
        'has_reminder': note.hasReminder,
      }).select().single();

      return Note.fromMap(response);
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<List<Note>> getNotes({int? folderId}) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      PostgrestFilterBuilder<PostgrestList> query = supabase
          .from('notes')
          .select('*')
          .eq('user_id', user.id);

      if (folderId != null) {
        query = query.eq('folder_id', folderId);
      } else {
        query = query.filter('folder_id', 'is', null);
      }

      final response = await query.order('created_at', ascending: false);
      final data = response as List<dynamic>;
      return data.map((note) => Note.fromMap(note)).toList();
    } else {
      return [];
    }
  }

  Future<void> updateNote(Note note) async {
    await supabase.from('notes').update({
      'title': note.title,
      'body': note.body,
      'folder_id': note.folderId,
      'has_reminder': note.hasReminder,
    }).eq('id', note.id!);
  }

  // Update the 'has_reminder' field of a note
  Future<void> updateNoteReminderStatus(int noteId, bool hasReminder) async {
    await supabase
        .from('notes')
        .update({'has_reminder': hasReminder})
        .eq('id', noteId);
  }

  Future<void> deleteNote(int id) async {
    await supabase.from('notes').delete().eq('id', id);
  }

  Future<Note?> getNoteById(int noteId) async {
    final response = await supabase
        .from('notes')
        .select('*')
        .eq('id', noteId)
        .maybeSingle();

    if (response != null) {
      return Note.fromMap(response);
    } else {
      return null;
    }
  }

  // ********** Folders CRUD Operations **********

  Future<void> insertFolder(Folder folder) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('folders').insert({
        'name': folder.name,
        'user_id': user.id,
      });
    }
  }

  Future<List<Folder>> getFolders() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('folders')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((folder) => Folder.fromMap(folder)).toList();
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<void> updateFolder(Folder folder) async {
    await supabase.from('folders').update({
      'name': folder.name,
    }).eq('id', folder.id);
  }

  Future<void> deleteFolder(int id) async {
    await supabase.from('notes').delete().eq('folder_id', id);
    await supabase.from('folders').delete().eq('id', id);
  }

  // ********** Reminders CRUD Operations **********

  Future<void> insertReminder(Reminder reminder) async {
    await supabase.from('reminders').insert(reminder.toMap());

    // Schedule the notification
    await _notificationService.scheduleNotification(
      reminder.noteId,
      (await getNoteById(reminder.noteId))?.title ?? '',
      'You have a reminder for this note!',
      reminder.reminderTime,
    );
  }

  Future<void> deleteReminder(int noteId) async {
    await supabase.from('reminders').delete().eq('note_id', noteId);
    await _notificationService.cancelNotification(noteId);
  }

  // ********** Credentials Operations with SQLite **********

  Future<void> saveCredentials(String username, String password) async {
    final db = await sqliteDatabase;

    // Clear existing credentials (one user at a time)
    await db.delete('credentials');

    // Insert new credentials
    await db.insert('credentials', {'username': username, 'password': password});
  }

  Future<Map<String, String>?> getCredentials() async {
    final db = await sqliteDatabase;
    final result = await db.query('credentials', limit: 1);

    if (result.isNotEmpty) {
      return {
        'username': result.first['username'] as String,
        'password': result.first['password'] as String,
      };
    }
    return null;
  }

  Future<void> deleteCredentials() async {
    final db = await sqliteDatabase;
    await db.delete('credentials');
  }

  // Close the database
  Future close() async {
    final db = await sqliteDatabase;
    db.close();
  }
}