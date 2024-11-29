// ai_features.dart

import 'package:flutter/material.dart';
import '../services/summarization_service.dart';
import '../services/suggestion_service.dart';

class AiFeatures extends StatefulWidget {
  final String noteContent;

  const AiFeatures({Key? key, required this.noteContent}) : super(key: key);

  @override
  _AiFeaturesState createState() => _AiFeaturesState();
}

class _AiFeaturesState extends State<AiFeatures> {
  final SummarizationService _summarizationService = SummarizationService();
  final SuggestionService _suggestionService = SuggestionService();

  String _summary = '';
  List<String> _suggestions = [];
  bool _isLoadingSummary = false;
  bool _isLoadingSuggestions = false;

  Future<void> _summarizeContent() async {
    setState(() {
      _isLoadingSummary = true;
    });
    try {
      final summary =
          await _summarizationService.summarizeText(widget.noteContent);
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error summarizing content: $e')),
      );
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _generateSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });
    try {
      final suggestions =
          await _suggestionService.generateSuggestions(widget.noteContent);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating suggestions: $e')),
      );
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool _hasResults = _summary.isNotEmpty || _suggestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Summarize Note',
            onPressed: _isLoadingSummary ? null : _summarizeContent,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'Get AI Suggestions',
            onPressed: _isLoadingSuggestions ? null : _generateSuggestions,
          ),
        ],
      ),
      body: Center(
        child: _isLoadingSummary || _isLoadingSuggestions
            ? const CircularProgressIndicator()
            : _hasResults
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Display Summary
                        if (_summary.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              _summary,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ),
                        const SizedBox(height: 24.0),
                        // Display Suggestions
                        if (_suggestions.isNotEmpty)
                          Expanded(
                            child: ListView.separated(
                              itemCount: _suggestions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.touch_app,
                                      color: Colors.blue),
                                  title: Text(_suggestions[index]),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style:
                              const TextStyle(fontSize: 16.0, color: Colors.white),
                          children: [
                            const TextSpan(text: 'Tap '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.description,
                                size: 24.0,
                                color: Colors.white,
                              ),
                            ),
                            const TextSpan(
                                text: ' to summarize the note and '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.lightbulb,
                                size: 24.0,
                                color: Colors.white,
                              ),
                            ),
                            const TextSpan(
                                text: ' to get suggestions for the note.'),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}