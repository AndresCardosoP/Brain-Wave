// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/note.dart';
import '../models/folder.dart';
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
  List<Folder> _folders = [];
  Folder? _selectedFolder;

  @override
  void initState() {
    super.initState();
    _refreshFolderList();
    _refreshNoteList();
  }

  // Fetch folders from the database
  void _refreshFolderList() async {
    List<Folder> folders = await _dbHelper.getFolders();
    setState(() {
      _folders = folders;
    });
  }

  // Fetch notes from the database
  void _refreshNoteList() async {
    List<Note> notes = await _dbHelper.getNotes(folderId: _selectedFolder?.id);
    setState(() {
      _notes = notes;
    });
  }

  // Navigate to the Note Editor to add or edit a note
  void _navigateToEditor({Note? note}) async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: note,
          initialFolderId: _selectedFolder?.id,
        ),
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
        title: const Text('Delete Note?'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteNote(id);
              Navigator.pop(context);
              _refreshNoteList();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Build the list item for each note
  Widget _buildNoteItem(Note note) {
    return ListTile(
      leading: note.attachmentPath != null
          ? Image.file(
              File(note.attachmentPath!),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : null,
      title: Text(note.title),
      subtitle: Text(
        note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteNoteConfirm(note.id!),
      ),
      onTap: () => _navigateToEditor(note: note),
    );
  }

  // Add a new folder
  void _addFolder() {
    String folderName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          onChanged: (value) => folderName = value,
          decoration: const InputDecoration(hintText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (folderName.isNotEmpty) {
                await _dbHelper.insertFolder(Folder(name: folderName));
                Navigator.pop(context);
                _refreshFolderList();
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Delete a folder
  void _deleteFolderConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text('This will remove the folder and unassign its notes. Continue?'),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteFolder(id);
              Navigator.pop(context);
              setState(() {
                _selectedFolder = null;
              });
              _refreshFolderList();
              _refreshNoteList();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Build the drawer with folders
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Text('Folders', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            title: const Text('All Notes'),
            selected: _selectedFolder == null,
            onTap: () {
              setState(() {
                _selectedFolder = null;
                Navigator.pop(context);
                _refreshNoteList();
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                Folder folder = _folders[index];
                return ListTile(
                  title: Text(folder.name),
                  selected: _selectedFolder?.id == folder.id,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFolderConfirm(folder.id!),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedFolder = folder;
                      Navigator.pop(context);
                      _refreshNoteList();
                    });
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Folder'),
            onTap: () {
              Navigator.pop(context);
              _addFolder();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedFolder?.name ?? 'All Notes'),
      ),
      drawer: _buildDrawer(),
      body: _notes.isEmpty
          ? const Center(child: Text('No notes available. Tap "+" to add a new note.'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) => _buildNoteItem(_notes[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}