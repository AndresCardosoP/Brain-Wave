// lib/screens/folder_edit.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder.dart';
import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import '../services/constant.dart';

class FolderEdit extends StatefulWidget {
  final Folder folder;

  const FolderEdit({Key? key, required this.folder}) : super(key: key);

  @override
  _FolderEditState createState() => _FolderEditState();
}

class _FolderEditState extends State<FolderEdit> {
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  late String _folderName;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _folderName = widget.folder.name;
  }

  // Rename Folder
  void _renameFolder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Prevent renaming to "Notes"
      if (_folderName.trim().toLowerCase() == 'notes') {
        context.showErrorMessage('Folder name "Notes" is reserved.');
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        context.showErrorMessage('User not authenticated');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      Folder updatedFolder = Folder(id: widget.folder.id, name: _folderName.trim());

      try {
        await _supabaseService.updateFolder(updatedFolder, user.id);
        await _dbHelper.updateLocalFolder(updatedFolder);
        Navigator.pop(context, true); // Indicate that a refresh is needed
      } catch (e) {
        context.showErrorMessage('Error renaming folder: $e');
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Delete Folder
  void _deleteFolder() async {
    // Prevent deleting the default "Notes" folder
    if (widget.folder.name.toLowerCase() == 'notes') {
      context.showErrorMessage('Cannot delete the default "Notes" folder.');
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: const Text('Are you sure you want to delete this folder? This will unassign its notes.'),
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
      setState(() {
        _isProcessing = true;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        context.showErrorMessage('User not authenticated');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      try {
        await _supabaseService.deleteFolder(widget.folder.id!, user.id);
        await _dbHelper.deleteLocalFolder(widget.folder.id!);
        Navigator.pop(context, true); // Indicate that a refresh is needed
      } catch (e) {
        context.showErrorMessage('Error deleting folder: $e');
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Folder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isProcessing ? null : _deleteFolder,
            tooltip: 'Delete Folder',
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _folderName,
                      decoration: const InputDecoration(labelText: 'Folder Name'),
                      onSaved: (value) => _folderName = value ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a folder name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _renameFolder,
                      child: const Text('Rename Folder'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}