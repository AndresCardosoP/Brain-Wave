// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../models/folder.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ------------------- Folder Operations -------------------

  Future<void> insertFolder(Folder folder, String userId) async {
    try {
      final response = await _client.from('folders').insert({
        'name': folder.name,
        'user_id': userId,
      });

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      throw Exception('Failed to insert folder: $e');
    }
  }

  Future<List<Folder>> getFolders(String userId) async {
    try {
      final response = await _client
          .from('folders')
          .select()
          .eq('user_id', userId)
          .order('name', ascending: true);

      final data = response as List<dynamic>;

      return data.map((folder) => Folder(
            id: folder['id'],
            name: folder['name'],
          )).toList();
    } catch (e) {
      throw Exception('Failed to fetch folders: $e');
    }
  }

  Future<void> updateFolder(Folder folder, String userId) async {
    try {
      final response = await _client
          .from('folders')
          .update({'name': folder.name})
          .eq('id', folder.id!)
          .eq('user_id', userId);

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      throw Exception('Failed to update folder: $e');
    }
  }

  Future<void> deleteFolder(int id, String userId) async {
    try {
      final response = await _client
          .from('folders')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }

  // ------------------- Note Operations -------------------

  Future<void> insertNote(Note note, String userId) async {
    try {
      final response = await _client.from('notes').insert({
        'title': note.title,
        'body': note.content,
        'user_id': userId,
        'folder_id': note.folderId,
      });

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      throw Exception('Failed to insert note: $e');
    }
  }

  Future<List<Note>> getNotes(String userId, {int? folderId}) async {
    try {
      final query = _client.from('notes').select().eq('user_id', userId);

      if (folderId != null) {
        query.eq('folder_id', folderId);
      }

      query.order('created_at', ascending: false);

      final response = await query;

      final data = response as List<dynamic>;

      return data.map((note) => Note(
            id: note['id'],
            folderId: note['folder_id'],
            title: note['title'],
            content: note['body'],
            timestamp: note['created_at'],
          )).toList();
    } catch (e) {
      throw Exception('Failed to fetch notes: $e');
    }
  }

  Future<void> updateNote(Note note, String userId) async {
    try {
      final response = await _client.from('notes').update({
        'title': note.title,
        'body': note.content,
        'folder_id': note.folderId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', note.id!).eq('user_id', userId);

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(int id, String userId) async {
    try {
      final response = await _client.from('notes').delete().eq('id', id).eq('user_id', userId);

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Additional methods can be added here
}