// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../services/db_helper.dart';
import 'note_editor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper.instance();
  List<Note> _notes = [];
  List<Folder> _folders = [];
  Folder? _selectedFolder;

  // Search related variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _checkAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
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
    try {
      List<Folder> folders = await _dbHelper.getFolders();
      setState(() {
        _folders = folders;
      });
    } catch (e) {
      // Handle error (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching folders: $e')),
      );
    }
  }

  // Fetch notes from the database
  void _refreshNoteList() async {
    try {
      List<Note> notes =
          await _dbHelper.getNotes(folderId: _selectedFolder?.id);
      if (_searchQuery.isNotEmpty) {
        notes = notes.where((note) {
          return note.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              note.body.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
      setState(() {
        _notes = notes;
      });
    } catch (e) {
      // Handle error (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notes: $e')),
      );
    }
  }

  // Navigate to the Note Editor to add or edit a note
  Future<void> _navigateToEditor({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditor(note: note)),
    );
    _refreshNoteList(); // Refresh notes after returning
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
                    const SnackBar(
                        content: Text('Folder name "Notes" is reserved.')),
                  );
                  return;
                }
                await _dbHelper.insertFolder(Folder(
                  id: DateTime.now()
                      .millisecondsSinceEpoch, // provide a unique id
                  name: folderName.trim(),
                  userId: 'your_user_id', // replace with actual user id
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
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
        final TextEditingController controller =
            TextEditingController(text: folder.name);
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
                      const SnackBar(
                          content: Text('Folder name "Notes" is reserved.')),
                    );
                    return;
                  }
                  await _dbHelper.updateFolder(Folder(
                    id: folder.id,
                    name: newFolderName.trim(),
                    userId: folder.userId,
                    createdAt: folder.createdAt,
                    updatedAt: DateTime.now(),
                  ));
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
        content: const Text(
            'This will remove the folder and all the notes inside. Continue?'),
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
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.grey),
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
                      _refreshNoteList(); // Fetch notes for the selected folder
                    });
                  },
                  trailing: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameFolder(folder);
                      } else if (value == 'delete') {
                        _deleteFolderConfirm(folder.id);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Rename',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.black)),
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
    DateTime noteTime =
        DateTime.parse(timestamp).toLocal(); // Convert to local time
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
                const SizedBox(height: 8.0),
                Text(
                  note.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(note.updatedAt?.toIso8601String() ?? ''),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Positioned(
              bottom: 2.0,
              right: 30.0,
              child: GestureDetector(
                onTap: () => _toggleReminder(note),
                child: Icon(
                  Icons.notifications,
                  color: note.hasReminder ? Colors.blue : Colors.grey,
                  size: 20,
                ),
              ),
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

  Future<void> _toggleReminder(Note note) async {
  if (note.hasReminder) {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text('Are you sure you want to delete the reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteReminder(note.id!);
        await _dbHelper.updateNoteReminderStatus(note.id!, false);
        setState(() {
          note.hasReminder = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reminder: $e')),
        );
      }
    }
  } else {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime reminderDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Ask if the user wants to add a location
        bool? addLocation = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add Location'),
            content: const Text('Would you like to add a location to this reminder?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
            ],
          ),
        );

        String? location;
        if (addLocation == true) {
          // Choose between manual entry or current location
          location = await _promptForLocation();
        }

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            await _dbHelper.insertReminder(
              Reminder(
                noteId: note.id!,
                userId: user.id,
                reminderTime: reminderDateTime,
                location: location,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            await _dbHelper.updateNoteReminderStatus(note.id!, true);
            setState(() {
              note.hasReminder = true;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding reminder: $e')),
            );
          }
        }
      }
    }
  }
}

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  Future<String?> _promptForLocation() async {
  String? location;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Get current location
                try {
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    permission = await Geolocator.requestPermission();
                    if (permission != LocationPermission.whileInUse &&
                        permission != LocationPermission.always) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Location permissions are denied')),
                      );
                      return;
                    }
                  }

                  Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high);

                  // (Optional) Convert position to address using Geocoding
                  List<Placemark> placemarks = await GeocodingPlatform.instance!
                      .placemarkFromCoordinates(position.latitude, position.longitude);
                  if (placemarks.isNotEmpty) {
                    Placemark placemark = placemarks.first;
                    location =
                        '${placemark.street}, ${placemark.locality}, ${placemark.country}';
                  } else {
                    location = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
                  }

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error getting location: $e')),
                  );
                }
              },
              child: const Text('Use Current Location'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // Manual entry
                TextEditingController controller = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enter Location'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: 'Enter location'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          location = controller.text;
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Enter Manually'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
  return location;
}

  Future<String?> _getCurrentLocation() async {
  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, prompt the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location services are disabled.')),
    );
    return null;
  }

  // Check location permissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are denied.')),
      );
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Location permissions are permanently denied.')),
    );
    return null;
  }

  // Get the current position
  Position position = await Geolocator.getCurrentPosition();
  return '${position.latitude},${position.longitude}';
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Supabase.instance.client.auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
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
