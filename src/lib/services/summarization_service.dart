import 'dart:convert';
import 'package:http/http.dart' as http;

class SummarizationService {
  // Replace with your actual API key
  static const String apiKey = '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';
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> summarizeText(String text) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are an assistant that summarizes text concisely.'},
          {'role': 'user', 'content': text}
        ],
        'max_tokens': 100,
        'temperature': 0.3, // Lower temperature for more focused summaries
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      print('Error: ${response.body}');
      throw Exception('Failed to summarize text: ${response.body}');
    }
  }
}
