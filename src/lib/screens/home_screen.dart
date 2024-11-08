// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/folder.dart';
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
  List<Folder> _folders = [];
  Folder? _selectedFolder;

  // Search related variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _refreshFolderList();
    _refreshNoteList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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
    if (_searchQuery.isNotEmpty) {
      notes = notes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
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

  // Rename a folder
  void _renameFolder(Folder folder) {
    String newFolderName = folder.name;
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController(text: folder.name);
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: controller,
            onChanged: (value) => newFolderName = value,
            decoration: const InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newFolderName.isNotEmpty) {
                  // Prevent renaming to "Notes"
                  if (newFolderName.trim().toLowerCase() == 'notes') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Folder name "Notes" is reserved.')),
                    );
                    return;
                  }
                  await _dbHelper.updateFolder(Folder(id: folder.id, name: newFolderName.trim()));
                  Navigator.pop(context);
                  _refreshFolderList();
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Confirm deletion of a folder
  void _deleteFolderConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text('This will remove the folder and all the notes inside. Continue?'),
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
          // Drawer Header with Menu Icon to close the drawer
          Container(
            height: 80.0,
            color: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                const SizedBox(height: 30.0),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Close the drawer
                      },
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      'Folders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notes, color: Colors.black),
            title: const Text(
              'Notes',
              style: TextStyle(color: Colors.black),
            ),
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
              padding: EdgeInsets.zero, // Remove extra padding
              itemCount: _folders.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                Folder folder = _folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blue),
                  title: Text(
                    folder.name,
                    style: const TextStyle(color: Colors.black),
                  ),
                  selected: _selectedFolder?.id == folder.id,
                  onTap: () {
                    setState(() {
                      _selectedFolder = folder;
                      Navigator.pop(context);
                      _refreshNoteList();
                    });
                  },
                  trailing: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameFolder(folder);
                      } else if (value == 'delete') {
                        _deleteFolderConfirm(folder.id!);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Rename', style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Add Folder Button
          ListTile(
            leading: const Icon(Icons.add, color: Colors.black),
            title: const Text(
              'Add Folder',
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              _addFolder();
            },
          ),
        ],
      ),
    );
  }

  // Helper method to format timestamps
  String _formatTimestamp(String timestamp) {
    DateTime noteTime = DateTime.parse(timestamp);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (noteTime.isAfter(today)) {
      // Today
      return 'Today, ${DateFormat.jm().format(noteTime)}';
    } else if (noteTime.isAfter(yesterday)) {
      // Yesterday
      return 'Yesterday, ${DateFormat.jm().format(noteTime)}';
    } else {
      // Older dates
      return DateFormat.yMMMd().add_jm().format(noteTime);
    }
  }

  // Build the note item widget
  Widget _buildNoteItem(Note note) {
    return GestureDetector(
      onTap: () => _navigateToEditor(note: note),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4.0,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.attachmentPath != null && File(note.attachmentPath!).existsSync())
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(note.attachmentPath!)),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                const SizedBox(height: 8.0),
                Text(
                  note.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(note.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Positioned(
              bottom: 2.0,
              right: 2.0,
              child: GestureDetector(
                onTap: () => _deleteNoteConfirm(note.id!),
                child: const Icon(Icons.delete, color: Colors.grey, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
              )
            : Text(
                _selectedFolder?.name ?? 'Notes',
                style: const TextStyle(color: Colors.white),
              ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                      _refreshNoteList();
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _notes.isEmpty
          ? const Center(
              child: Text('No notes available. Tap "+" to add a new note.'),
            )
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Note',
      ),
    );
  }
}