// lib/screens/folder_view.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/note_editor.dart';
import '../models/note.dart';
import '../services/db_helper.dart';

class FolderView extends StatefulWidget {
  final int currentFolderId;

  const FolderView({Key? key, required this.currentFolderId}) : super(key: key);

  @override
  _FolderViewState createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  final DBHelper _dbHelper = DBHelper();
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  void _fetchNotes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }
    try {
      List<Note> notes = await _dbHelper.getNotes(folderId: widget.currentFolderId);
      setState(() {
        _notes = notes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Notes'),
      ),
      body: _notes.isEmpty
          ? const Center(child: Text('No notes in this folder'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return ListTile(
                  title: Text(note.title),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEditor(note: note),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) {
                        _fetchNotes();
                      }
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditor(
                initialFolderId: widget.currentFolderId,
              ),
            ),
          ).then((shouldRefresh) {
            if (shouldRefresh == true) {
              _fetchNotes();
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Note',
      ),
    );
  }
}