import 'dart:convert';
import 'package:http/http.dart' as http;

class SuggestionService {
  static const String apiKey = 'yRULgDEK0KO8nv0pDxIOjpXokijK1KlgodyLLdSi';
  static const String apiUrl = 'https://api.cohere.ai/generate';

  Future<List<String>> generateSuggestions(String text) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'command-xlarge-nightly',
        'prompt': 'Suggest follow-up questions or actions based on the following note content:\n\n$text',
        'max_tokens': 50,
        'temperature': 0.7,
      }),
    );

    // Log full response for debugging
    print('Full API response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if the 'text' field exists and contains valid data
      if (data != null && data['text'] is String) {
        final suggestionsText = data['text'] as String;

        // Split the suggestions into a list of strings, handling nulls and invalid types
        final suggestions = suggestionsText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        print('Processed suggestions: $suggestions');
        return suggestions;
      } else {
        throw Exception('Unexpected response structure: "text" field is missing or not a string.');
      }
    } else {
      // Log error response for debugging
      print('Error: ${response.body}');
      throw Exception('Failed to generate suggestions: ${response.body}');
    }
  }
}