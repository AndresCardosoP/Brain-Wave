// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/db_helper.dart';
import 'note_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _refreshNoteList();
  }

  // Fetch notes from the database
  void _refreshNoteList() async {
    List<Note> notes = await _dbHelper.getNotes();
    setState(() {
      _notes = notes;
    });
  }

  // Navigate to the Note Editor to add or edit a note
  void _navigateToEditor({Note? note}) async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(note: note),
      ),
    );
    if (shouldRefresh == true) {
      _refreshNoteList();
    }
  }

  // Confirm deletion of a note
  void _deleteNoteConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note?'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteNote(id);
              Navigator.pop(context);
              _refreshNoteList();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Build the list item for each note
  Widget _buildNoteItem(Note note) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(
        note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteNoteConfirm(note.id!),
      ),
      onTap: () => _navigateToEditor(note: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BrainWave Notes'),
      ),
      body: _notes.isEmpty
          ? Center(child: Text('No notes available. Tap "+" to add a new note.'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) => _buildNoteItem(_notes[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}