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
          style: const TextStyle(color: Colors.red),
        ),
        backgroundColor: Colors.grey,
      ),
    );
  }
}
