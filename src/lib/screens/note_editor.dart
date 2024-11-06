// lib/screens/note_editor.dart

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/db_helper.dart';

class NoteEditor extends StatefulWidget {
  final Note? note; // If null, this is a new note

  const NoteEditor({Key? key, this.note}) : super(key: key);

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _content;
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? '';
    _content = widget.note?.content ?? '';
  }

  // Save the note to the database
  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Note note = Note(
        id: widget.note?.id,
        title: _title,
        content: _content,
        timestamp: DateTime.now(),
      );

      if (widget.note == null) {
        // Insert a new note
        await _dbHelper.insertNote(note);
      } else {
        // Update an existing note
        await _dbHelper.updateNote(note);
      }

      Navigator.pop(context, true); // Indicate that the notes list should refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title Field
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _title = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16.0),
              // Content Field
              Expanded(
                child: TextFormField(
                  initialValue: _content,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => _content = value ?? '',
                  maxLines: null,
                  expands: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter content' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}