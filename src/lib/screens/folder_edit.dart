// src/lib/screens/folder_edit.dart

import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../services/db_helper.dart';

class FolderEdit extends StatefulWidget {
  final Folder folder;

  const FolderEdit({Key? key, required this.folder}) : super(key: key);

  @override
  _FolderEditState createState() => _FolderEditState();
}

class _FolderEditState extends State<FolderEdit> {
  final _formKey = GlobalKey<FormState>();
  late String _folderName;
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _folderName = widget.folder.name;
  }

  void _renameFolder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Prevent renaming to "Notes"
      if (_folderName.trim().toLowerCase() == 'notes') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder name "Notes" is reserved.')),
        );
        return;
      }
      Folder updatedFolder = Folder(id: widget.folder.id, name: _folderName.trim());
      await _dbHelper.updateFolder(updatedFolder);
      Navigator.pop(context, true); // Indicate that a refresh is needed
    }
  }

  void _deleteFolder() async {
    // Prevent deleting the default "Notes" folder
    if (widget.folder.name.toLowerCase() == 'notes') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the default "Notes" folder.')),
      );
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
      await _dbHelper.deleteFolder(widget.folder.id!);
      Navigator.pop(context, true); // Indicate that a refresh is needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Folder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                initialValue: _folderName,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _folderName = value!.trim(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a folder name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _renameFolder,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteFolder,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Folder'),
            ),
          ],
        ),
      ),
    );
  }
}