import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [client] for Supabase instance

final client = Supabase.instance.client;

/// Custom SnackBar
extension ShowSnackBar on BuildContext {
  void showErrorMessage(String text) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
