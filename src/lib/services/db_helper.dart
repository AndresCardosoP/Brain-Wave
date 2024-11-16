// src/lib/services/db_helper.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/note.dart';
import '../models/folder.dart';
import '../models/reminder.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DBHelper {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  DBHelper() {
    tz.initializeTimeZones();
  }

  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper.instance() => _instance;
  DBHelper._internal();

  final supabase = Supabase.instance.client;

  // Notes CRUD operations

  // Insert a new note into the database
  Future<void> insertNote(Note note) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('notes').insert({
        'title': note.title,
        'body': note.body,
        'user_id': user.id,
        'folder_id': note.folderId,
        'has_reminder': note.hasReminder,
      });
    }
  }

  // Retrieve all notes from the database
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

  // Update an existing note
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

  // Delete a note
  Future<void> deleteNote(int id) async {
    await supabase.from('notes').delete().eq('id', id);
  }

  // Folders CRUD operations

  // Insert a new folder into the database
  Future<void> insertFolder(Folder folder) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('folders').insert({
        'name': folder.name,
        'user_id': user.id,
      });
    }
  }

  // Retrieve all folders from the database
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

  // Update a folder's name
  Future<void> updateFolder(Folder folder) async {
    await supabase.from('folders').update({
      'name': folder.name,
    }).eq('id', folder.id);
  }

  // Delete a folder and all its associated notes from the database
  Future<void> deleteFolder(int id) async {
    // Delete all notes associated with the folder
    await supabase.from('notes').delete().eq('folder_id', id);

    // Delete the folder
    await supabase.from('folders').delete().eq('id', id);
  }

  // Reminders CRUD operations

  // Insert a new reminder
  Future<void> insertReminder(Reminder reminder) async {
    await supabase.from('reminders').insert(reminder.toMap());
  }

  // Delete a reminder
  Future<void> deleteReminder(int noteId) async {
    await supabase.from('reminders').delete().eq('note_id', noteId);
  }

  // Check if a reminder exists for a note
  Future<bool> hasReminder(int noteId) async {
    final response = await supabase
        .from('reminders')
        .select('*')
        .eq('note_id', noteId)
        .maybeSingle();

    return response != null;
  }
}