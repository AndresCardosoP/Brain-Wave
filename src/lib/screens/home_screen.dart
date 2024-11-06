// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'note_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BrainWave Notes'),
      ),
      body: Center(
        child: Text('Welcome to BrainWave!'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Note Editor
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteEditor()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}