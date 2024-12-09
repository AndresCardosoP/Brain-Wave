import 'dart:convert'; 
import 'package:http/http.dart' as http; 

// A service class for summarizing text using OpenAI's API
class SummarizationService {
  // API key for authenticating with OpenAI's service
  static const String apiKey = 'YOUR-API-KEY-HERE';

  // URL endpoint for OpenAI's chat completions API
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Method to send a text input to OpenAI API for summarization
  Future<String> summarizeText(String text) async {
    // Sending a POST request to the OpenAI API
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey', 
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo', // Specify the model to use for summarization
        'messages': [
          {'role': 'system', 'content': 'You are an assistant that summarizes text concisely.'}, // System message to set the behavior of the assistant
          {'role': 'user', 'content': text} // User message containing the text to summarize
        ],
        'max_tokens': 100, // Limit the number of tokens in the response
        'temperature': 0.3, // Lower temperature for more deterministic output
      }),
    );

    // Handling the API response
    if (response.statusCode == 200) {
  
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim(); 
    } else {
      print('Error: ${response.body}');
      throw Exception('Failed to summarize text: ${response.body}');
    }
  }
}
