// lib/screens/note_editor.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import '../services/constant.dart';

class NoteEditor extends StatefulWidget {
  final Note? note; // If null, this is a new note
  final int? initialFolderId; // Current folder ID

  const NoteEditor({Key? key, this.note, this.initialFolderId}) : super(key: key);

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final DBHelper _dbHelper = DBHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _content;
  int? _selectedFolderId;

  List<Folder> _folders = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? '';
    _content = widget.note?.content ?? '';
    _selectedFolderId = widget.note?.folderId ?? widget.initialFolderId;
    _loadFoldersFromDb();
  }

  // Load folders from Supabase
  void _loadFoldersFromDb() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      context.showErrorMessage('User not authenticated');
      return;
    }

    try {
      List<Folder> foldersFromDb = await _supabaseService.getFolders(user.id);
      setState(() {
        _folders = foldersFromDb;
      });
    } catch (e) {
      context.showErrorMessage('Error loading folders: $e');
    }
  }

  // Save the note to both local SQLite and Supabase
  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSaving = true;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        context.showErrorMessage('User not authenticated');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      Note note = Note(
        id: widget.note?.id,
        folderId: _selectedFolderId, // This can now be null
        title: _title,
        content: _content,
        timestamp: DateTime.now().toIso8601String(),
      );

      try {
        if (widget.note == null) {
          // Create new note
          await _supabaseService.insertNote(note, user.id);
          await _dbHelper.insertLocalNote(note);
        } else {
          // Update existing note
          await _supabaseService.updateNote(note, user.id);
          await _dbHelper.updateLocalNote(note);
        }
        Navigator.pop(context, true); // Indicate that the notes list should refresh
      } catch (e) {
        context.showErrorMessage('Error saving note: $e');
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still loading folders, show a loading indicator
    if (_folders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Create Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title Field
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onSaved: (value) => _title = value ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Content Field
                    Expanded(
                      child: TextFormField(
                        initialValue: _content,
                        decoration: const InputDecoration(labelText: 'Content'),
                        maxLines: null,
                        expands: true,
                        onSaved: (value) => _content = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter content';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Folder Dropdown
                    DropdownButtonFormField<int?>(
                      value: _selectedFolderId,
                      decoration: const InputDecoration(labelText: 'Folder'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Uncategorized'),
                        ),
                        ..._folders.map((folder) {
                          return DropdownMenuItem<int?>(
                            value: folder.id,
                            child: Text(folder.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFolderId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}