// lib/screens/note_editor.dart

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/db_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteEditor extends StatefulWidget {
  final Note? note; // If null, this is a new note
  final int? initialFolderId; // Current folder ID

  const NoteEditor({Key? key, this.note, this.initialFolderId}) : super(key: key);

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();

  String _title = '';
  String _content = '';
  int? _selectedFolderId;
  List<Folder> _folders = [];

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? '';
    _content = widget.note?.body ?? '';
    _selectedFolderId = widget.note?.folderId ?? widget.initialFolderId;
    _loadFoldersFromDb();
  }

  // Load folders from the database
  void _loadFoldersFromDb() async {
    try {
      List<Folder> foldersFromDb = await _dbHelper.getFolders();
      setState(() {
        _folders = foldersFromDb;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading folders: $e')),
      );
    }
  }

  // Save the note to the database
  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      Note note = Note(
        id: widget.note?.id ?? 0, // Provide a default value for new notes
        title: _title,
        body: _content,
        userId: user.id,
        folderId: _selectedFolderId,
        attachmentPath: null, // Adjust if handling attachments
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.note == null) {
          await _dbHelper.insertNote(note);
        } else {
          await _dbHelper.updateNote(note);
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    // If folders are still loading, show a loading indicator
    if (_folders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Loading...', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: _selectedFolderId,
            dropdownColor: Colors.blue,
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: const Text('No Folder', style: TextStyle(color: Colors.white)),
              ),
              ..._folders.map((folder) {
                return DropdownMenuItem<int?>(
                  value: folder.id,
                  child: Text(folder.name, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFolderId = value;
              });
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Title Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextFormField(
                initialValue: _title,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                onSaved: (value) => _title = value?.trim() ?? '',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
            ),
            // Divider Line
            const Divider(
              color: Colors.grey,
              height: 1,
              thickness: 0.5,
            ),
            // Content Input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  initialValue: _content,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Start typing your note...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                  onSaved: (value) => _content = value?.trim() ?? '',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter some content';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}