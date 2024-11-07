// lib/screens/note_editor.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/db_helper.dart';

class NoteEditor extends StatefulWidget {
  final Note? note; // If null, this is a new note
  final int? initialFolderId; // Current folder ID

  const NoteEditor({Key? key, this.note, this.initialFolderId}) : super(key: key);

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _content;
  int? _selectedFolderId; // Selected folder ID
  List<Folder> _folders = [];
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();

  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? '';
    _content = widget.note?.content ?? '';
    _selectedFolderId = null; // Initialize as null
    if (widget.note?.attachmentPath != null) {
      _attachedImage = File(widget.note!.attachmentPath!);
    }
    _loadFoldersFromDb();
    // Debugging
    print('Note Editor Init: _selectedFolderId = $_selectedFolderId');
  }

  void _loadFoldersFromDb() async {
    try {
      List<Folder> foldersFromDb = await _dbHelper.getFolders();

      // Debugging: Print all fetched folders
      print('Fetched Folders from DB:');
      for (var folder in foldersFromDb) {
        print('Folder ID: ${folder.id}, Name: ${folder.name}');
      }

      // Remove duplicate folders based on ID
      final uniqueFolders = <int, Folder>{};
      for (var folder in foldersFromDb) {
        if (folder.id != null && !uniqueFolders.containsKey(folder.id)) {
          uniqueFolders[folder.id!] = folder;
        } else {
          print('Duplicate folder detected with ID: ${folder.id} and Name: ${folder.name}');
        }
      }

      _folders = uniqueFolders.values.toList();

      // Debugging: Print folders after removing duplicates
      print('Unique Folders after processing:');
      for (var folder in _folders) {
        print('Folder ID: ${folder.id}, Name: ${folder.name}');
      }

      // Validate and set _selectedFolderId
      if (widget.note?.folderId != null &&
          _folders.any((folder) => folder.id == widget.note!.folderId)) {
        _selectedFolderId = widget.note!.folderId;
      } else if (widget.initialFolderId != null &&
          _folders.any((folder) => folder.id == widget.initialFolderId)) {
        _selectedFolderId = widget.initialFolderId;
      } else {
        _selectedFolderId = null;
      }

      setState(() {});
      // Final Debugging
      print('Final _selectedFolderId after validation: $_selectedFolderId');
    } catch (e) {
      print('Error loading folders: $e');
    }
  }

  // Save the note to the database
  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Note note = Note(
        id: widget.note?.id,
        folderId: _selectedFolderId, // Use selected folder ID
        title: _title,
        content: _content,
        timestamp: DateTime.now().toIso8601String(),
        attachmentPath: _attachedImage?.path,
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

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // Or ImageSource.camera
    if (image != null) {
      setState(() {
        _attachedImage = File(image.path);
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Debugging: Print current state before building UI
    print('Building Note Editor: _selectedFolderId = $_selectedFolderId');
    print('Folders available for Dropdown: ${_folders.map((f) => 'ID: ${f.id}, Name: ${f.name}').join(', ')}');

    // Show a loading indicator if folders are still loading
    if (_folders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Save Note',
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
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
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _title = value ?? '',
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16.0),
              // Folder Selection
              DropdownButtonFormField<int?>(
                value: _selectedFolderId,
                decoration: const InputDecoration(labelText: 'Folder', border: OutlineInputBorder()),
                items: [
                  // "No Folder" option
                  DropdownMenuItem<int?>(
                    value: null,
                    child: const Text('No Folder'),
                  ),
                  // Existing folders
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
              const SizedBox(height: 16.0),
              // Content Field
              Expanded(
                child: TextFormField(
                  initialValue: _content,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => _content = value ?? '',
                  maxLines: null,
                  expands: true,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter content' : null,
                ),
              ),
              // Attachment Section
              const SizedBox(height: 16.0),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach Image'),
                  ),
                  const SizedBox(width: 16.0),
                  if (_attachedImage != null)
                    ElevatedButton.icon(
                      onPressed: _removeAttachment,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove Attachment'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                ],
              ),
              if (_attachedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(
                    _attachedImage!,
                    height: 200,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}