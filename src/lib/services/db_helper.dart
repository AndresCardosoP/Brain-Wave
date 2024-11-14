// src/lib/services/db_helper.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../models/folder.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
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
        'attachment_path': note.attachmentPath,
      });
    }
  }

  // Retrieve all notes from the database
  Future<List<Note>> getNotes({int? folderId}) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      var query = supabase
          .from('notes')
          .select()
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
      'attachment_path': note.attachmentPath,
    }).eq('id', note.id!);
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
          .select()
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
}