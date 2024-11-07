// src/lib/screens/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/db_helper.dart';
import 'note_editor.dart';
import 'folder_edit.dart'; // Import the FolderEdit screen

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
                // Prevent creating a folder named "Notes"
                if (folderName.trim().toLowerCase() == 'notes') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folder name "Notes" is reserved.')),
                  );
                  return;
                }
                await _dbHelper.insertFolder(Folder(name: folderName.trim()));
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
            leading: const Icon(Icons.notes),
            title: const Text('Notes'), // Renamed from 'All Notes' to 'Notes'
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
            child: ListView.separated(
              itemCount: _folders.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                Folder folder = _folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blue),
                  title: Text(folder.name),
                  selected: _selectedFolder?.id == folder.id,
                  onTap: () {
                    setState(() {
                      _selectedFolder = folder;
                      Navigator.pop(context);
                      _refreshNoteList();
                    });
                  },
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderEdit(folder: folder),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) {
                        _refreshFolderList();
                        _refreshNoteList();
                      }
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

  // Build the grid item for each note
  Widget _buildNoteItem(Note note) {
    return GestureDetector(
      onTap: () => _navigateToEditor(note: note),
      onLongPress: () => _deleteNoteConfirm(note.id!),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.attachmentPath != null)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  image: DecorationImage(
                    image: FileImage(File(note.attachmentPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: const Icon(Icons.note, size: 50, color: Colors.blue),
              ),
            const SizedBox(height: 8.0),
            Text(
              note.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              note.timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedFolder?.name ?? 'Notes'),
      ),
      drawer: _buildDrawer(),
      body: _notes.isEmpty
          ? const Center(child: Text('No notes available. Tap "+" to add a new note.'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: _notes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 3 / 4, // Width / Height ratio
                ),
                itemBuilder: (context, index) => _buildNoteItem(_notes[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}