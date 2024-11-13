// lib/screens/folder_view.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import '../services/constant.dart';
import 'note_editor.dart';
import 'login_screen.dart';

class FolderView extends StatefulWidget {
  final int currentFolderId; // ID of the current folder

  const FolderView({Key? key, required this.currentFolderId}) : super(key: key);

  @override
  _FolderViewState createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  final DBHelper _dbHelper = DBHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  List<Note> _notes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  // Fetch notes from Supabase
  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });

    final user = _client.auth.currentUser;
    if (user == null) {
      context.showErrorMessage('User not authenticated');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    try {
      List<Note> fetchedNotes = await _supabaseService.getNotes(
        user.id,
        folderId: widget.currentFolderId,
      );
      setState(() {
        _notes = fetchedNotes;
      });

      // Optionally, sync with local SQLite
      await _syncLocalNotes(fetchedNotes);
    } catch (e) {
      context.showErrorMessage('Error fetching notes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Synchronize notes with local SQLite
  Future<void> _syncLocalNotes(List<Note> cloudNotes) async {
    for (var note in cloudNotes) {
      await _dbHelper.insertLocalNote(note);
    }
    // Implement further synchronization logic if needed
  }

  // Navigate to the Note Editor to add or edit a note
  void _navigateToEditor({Note? note}) async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: note,
          initialFolderId: widget.currentFolderId,
        ),
      ),
    );

    if (shouldRefresh == true) {
      _fetchNotes(); // Refresh both local and cloud data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('No notes in this folder'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return ListTile(
                      title: Text(note.title),
                      subtitle: Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _navigateToEditor(note: note),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final user = _client.auth.currentUser;
                          if (user == null) {
                            context.showErrorMessage('User not authenticated');
                            return;
                          }

                          try {
                            await _supabaseService.deleteNote(note.id!, user.id);
                            await _dbHelper.deleteLocalNote(note.id!);
                            _fetchNotes();
                            context.showErrorMessage('Note deleted');
                          } catch (e) {
                            context.showErrorMessage('Error deleting note: $e');
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        tooltip: 'Create New Note',
      ),
    );
  }
}