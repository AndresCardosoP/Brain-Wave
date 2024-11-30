import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/db_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_features.dart';

class NoteEditor extends StatefulWidget {
  final Note? note; // If null, this is a new note
  final int? initialFolderId; // Current folder ID

  const NoteEditor({Key? key, this.note, this.initialFolderId}) : super(key: key);

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper.instance();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _summary = ''; // Stores the AI-generated summary
  Map<String, dynamic>? _suggestionWithFeedback; // Stores AI-generated suggestions
  int? _selectedFolderId; // Tracks the selected folder
  List<Folder> _folders = []; // List of folders fetched from the database
  bool _isLoadingFolders = true; // Flag to track folder loading state

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note?.title ?? '';
    _contentController.text = widget.note?.body ?? '';
    _selectedFolderId = widget.note?.folderId ?? widget.initialFolderId;
    _loadFoldersFromDb();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Load folders from the database
  void _loadFoldersFromDb() async {
    try {
      List<Folder> foldersFromDb = await _dbHelper.getFolders();
      setState(() {
        _folders = foldersFromDb;
        if (widget.note == null && widget.initialFolderId != null) {
          bool folderExists = foldersFromDb.any((folder) => folder.id == widget.initialFolderId);
          _selectedFolderId = folderExists ? widget.initialFolderId : null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading folders: $e')),
      );
    } finally {
      setState(() {
        _isLoadingFolders = false; // Update the loading flag
      });
    }
  }

  // Save the note to the database
  Future<void> _saveNote() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Note note = Note(
          id: widget.note?.id,
          title: _titleController.text.trim(),
          body: _contentController.text.trim(),
          userId: user.id,
          folderId: _selectedFolderId,
          createdAt: widget.note?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          hasReminder: widget.note?.hasReminder ?? false,
        );

        try {
          if (widget.note == null) {
            await _dbHelper.insertNote(note);
          } else {
            await _dbHelper.updateNote(note);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving note: $e')),
          );
        }
      }
    }
  }

  // Show a dialog to input template type
  Future<String> _showTemplateInputDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    String result = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Template Type'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'e.g., Meeting Notes'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                result = controller.text.trim();
                Navigator.pop(context);
              },
              child: Text('Generate'),
            ),
          ],
        );
      },
    );
    return result;
  }

  // Generate a detailed template dynamically or fallback to a predefined one
  Future<void> _generateTemplate(String templateType) async {
    try {
      // Simulate a detailed template generation
      final generatedContent = '''
# $templateType

## Overview
Provide a brief description or introduction about the $templateType.

## Key Points
- Point 1: Description
- Point 2: Description
- Point 3: Description

## Detailed Sections
### Section 1: Title
[Add details or notes here.]

### Section 2: Title
[Add details or notes here.]

## Action Items
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
''';
      setState(() {
        _contentController.text = generatedContent;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$templateType template generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating template: $e')),
      );
    }
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    if (_isLoadingFolders) { // Check the loading flag
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Loading...', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _saveNote();
        return true; // Allow the pop
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: IntrinsicWidth(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedFolderId,
                isDense: true,
                isExpanded: false,
                dropdownColor: Colors.blue,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                iconEnabledColor: Colors.white,
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedFolderId = newValue;
                  });
                },
                selectedItemBuilder: (BuildContext context) {
                  return [
                    const Text(
                      'Notes',
                      style: TextStyle(color: Colors.white),
                    ),
                    ..._folders.map<Widget>((Folder folder) {
                      return Text(
                        folder.name,
                        style: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ];
                },
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: const Text(
                      'Notes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ..._folders.map<DropdownMenuItem<int?>>((Folder folder) {
                    return DropdownMenuItem<int?>(
                      value: folder.id,
                      child: Text(
                        folder.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.white), // AI suggestion/summarization icon
              onPressed: () async {
                await _saveNote();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiFeatures(noteContent: _contentController.text, noteId: widget.note?.id ?? 0),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.white), // Magic wand icon
              onPressed: () async {
                String templateType = await _showTemplateInputDialog(context);
                if (templateType.isNotEmpty) {
                  _generateTemplate(templateType);
                }
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextFormField(
                  controller: _titleController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              const Divider(color: Colors.grey, height: 0.5, thickness: 0.2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Start typing your note...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter some content';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              if (_summary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Summary: $_summary',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              if (_suggestionWithFeedback != null)
                ExpansionTile(
                  title: Text('Suggestion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      title: Text(_suggestionWithFeedback!['text']),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
