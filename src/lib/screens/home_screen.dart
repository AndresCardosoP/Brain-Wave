// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import '../services/constant.dart';
import 'note_editor.dart';
import 'folder_edit.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  List<Note> _notes = [];
  List<Folder> _folders = [];
  Folder? _selectedFolder;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch data from both local and cloud
  Future<void> _fetchData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        // User not authenticated, navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }

      // Fetch folders from Supabase
      List<Folder> cloudFolders = await _supabaseService.getFolders(user.id);
      setState(() {
        _folders = cloudFolders;
      });

      // Optionally, sync with local SQLite
      // Here, you can implement logic to merge or overwrite local data with cloud data
      await _syncLocalData(cloudFolders, user.id);

      // Fetch notes from Supabase
      List<Note> cloudNotes =
          await _supabaseService.getNotes(user.id, folderId: _selectedFolder?.id);
      setState(() {
        _notes = cloudNotes;
      });

      // Optionally, sync with local SQLite
      await _syncLocalNotes(cloudNotes);
    } catch (e) {
      context.showErrorMessage('Error fetching data: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  // Synchronize folders with local SQLite
  Future<void> _syncLocalData(List<Folder> cloudFolders, String userId) async {
    for (var folder in cloudFolders) {
      await _dbHelper.insertLocalFolder(folder);
    }
    // Implement further synchronization logic if needed
  }

  // Synchronize notes with local SQLite
  Future<void> _syncLocalNotes(List<Note> cloudNotes) async {
    for (var note in cloudNotes) {
      await _dbHelper.insertLocalNote(note);
    }
    // Implement further synchronization logic if needed
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _filterNotes();
  }

  // Filter notes based on search query
  void _filterNotes() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      List<Note> fetchedNotes = await _supabaseService.getNotes(
        user.id,
        folderId: _selectedFolder?.id,
      );

      if (_searchQuery.isNotEmpty) {
        fetchedNotes = fetchedNotes.where((note) {
          return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      setState(() {
        _notes = fetchedNotes;
      });
    } catch (e) {
      context.showErrorMessage('Error filtering notes: $e');
    }
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
      _fetchData(); // Refresh both local and cloud data
    }
  }

  // Navigate to Folder Edit screen
  void _navigateToFolderEdit(Folder folder) async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderEdit(folder: folder),
      ),
    );

    if (shouldRefresh == true) {
      _fetchData();
    }
  }

  // Logout function
  void _logout() async {
    await _client.auth.signOut();
    // Navigation is handled by AuthState listener
  }

  @override
  Widget build(BuildContext context) {
    // If syncing data, show a loading indicator
    if (_isSyncing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('BrainWave'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BrainWave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Notes',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
            ),
          ),
          // Folders List
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFolder = folder;
                    });
                    _filterNotes();
                  },
                  onLongPress: () {
                    _navigateToFolderEdit(folder);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Chip(
                      label: Text(folder.name),
                      backgroundColor:
                          _selectedFolder?.id == folder.id ? Colors.blue : Colors.grey[300],
                    ),
                  ),
                );
              },
            ),
          ),
          // Notes List
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('No notes found'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return ListTile(
                        title: Text(note.title),
                        subtitle: Text(
                          note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _navigateToEditor(note: note),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final user = _client.auth.currentUser;
                            if (user == null) {
                              context.showErrorMessage('User not authenticated');
                              return;
                            }

                            try {
                              await _supabaseService.deleteNote(note.id!, user.id);
                              await _dbHelper.deleteLocalNote(note.id!);
                              _fetchData();
                              context.showErrorMessage('Note deleted');
                            } catch (e) {
                              context.showErrorMessage('Error deleting note: $e');
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        tooltip: 'Create New Note',
      ),
    );
  }
}