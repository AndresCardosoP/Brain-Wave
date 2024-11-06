// lib/screens/folder_view.dart

import 'package:flutter/material.dart';
import '../screens/note_editor.dart';

class FolderView extends StatelessWidget {
  final int currentFolderId; // ID of the current folder

  const FolderView({Key? key, required this.currentFolderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Your folder view UI
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditor(
                initialFolderId: currentFolderId, // Pass the current folder ID
              ),
            ),
          ).then((shouldRefresh) {
            if (shouldRefresh == true) {
              // Refresh the notes list if needed
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Note',
      ),
    );
  }
}