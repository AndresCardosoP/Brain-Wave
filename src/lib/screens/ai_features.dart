import 'package:flutter/material.dart';
import 'package:/src/services/summarization_service.dart';
import 'package:/src/services/suggestion_service.dart';
import 'package:/src/services/ai_local_db_helper.dart';

class AiFeatures extends StatefulWidget {
  final String noteContent;
  final int noteId; // Added noteId to link with database

  const AiFeatures({Key? key, required this.noteContent, required this.noteId}) : super(key: key);

  @override
  _AiFeaturesState createState() => _AiFeaturesState();
}

class _AiFeaturesState extends State<AiFeatures> {
  // Create instances of the services and database helper
  final SummarizationService _summarizationService = SummarizationService();
  final SuggestionService _suggestionService = SuggestionService();
  final AiLocalDbHelper _dbHelper = AiLocalDbHelper();

  // Define the properties for the summary and suggestions
  String _summary = '';
  List<String> _suggestions = [];
  bool _isLoadingSummary = false;
  bool _isLoadingSuggestions = false;

  // Load AI data when the widget is initialized
  @override
  void initState() {
    super.initState();
    _loadAiData();
  }

  // Load AI data from the database
  Future<void> _loadAiData() async {
    final data = await _dbHelper.getAiData(widget.noteId);
    if (data != null) {
      setState(() {
        _summary = data['summary'] ?? '';
        _suggestions = data['suggestions'] != null
            ? (data['suggestions'] as String).split('||')
            : [];
      });
    }
  }

  // Summarize the content of the note
  Future<void> _summarizeContent() async {
    setState(() {
      _isLoadingSummary = true;
    });
    try {
      final summary = await _summarizationService.summarizeText(widget.noteContent);
      setState(() {
        _summary = summary;
      });
      await _dbHelper.insertAiData(widget.noteId, _summary, _suggestions);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error summarizing content: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  // Generate suggestions for the note content
  Future<void> _generateSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });
    try {
      final suggestions = await _suggestionService.generateSuggestions(widget.noteContent);
      setState(() {
        _suggestions = suggestions;
      });
      await _dbHelper.insertAiData(widget.noteId, _summary, _suggestions);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error generating suggestions: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  // Clear AI data from the database
  Future<void> _clearAiData() async {
    await _dbHelper.deleteAiData(widget.noteId);
    setState(() {
      _summary = '';
      _suggestions = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'AI data cleared.',
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

  // Build the clear icon for the app bar
  Widget _buildClearIcon() {
    return IconButton(
      icon: Icon(Icons.clear),
      onPressed: _clearAiData,
      tooltip: 'Clear AI Data',
    );
  }

  // Build the widget tree for the AI features screen
  @override
  Widget build(BuildContext context) {
    // Check if the summary and suggestions are not empty
    bool _hasSummary = _summary.isNotEmpty;
    bool _hasSuggestions = _suggestions.isNotEmpty;

    return Scaffold(
      // Create the app bar with the title and actions
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
          if (_hasSummary || _hasSuggestions) _buildClearIcon(),
        ],
      ),
      body: Column(
        children: [
          // Summary Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Heading with Clear Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the heading
                    children: [
                      Expanded(
                        child: Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Content Box
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _isLoadingSummary
                          ? const Center(child: CircularProgressIndicator())
                          : _hasSummary
                              ? SingleChildScrollView(
                                  child: Text(
                                    _summary,
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.black),
                                    textAlign: TextAlign.justify,
                                  ),
                                )
                              : RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'Tap '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: const [
                                            Icon(
                                              Icons.description,
                                              size: 24.0,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const TextSpan(text: ' to summarize the note.'),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Suggestions Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Heading with Clear Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Content Box
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _isLoadingSuggestions
                          ? const Center(child: CircularProgressIndicator())
                          : _hasSuggestions
                              ? ListView.separated(
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: const Icon(Icons.lightbulb,
                                          color: Colors.blue),
                                      title: Text(
                                        _suggestions[index],
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    );
                                  },
                                )
                              : RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'Tap '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: const [
                                            Icon(
                                              Icons.lightbulb,
                                              size: 24.0,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const TextSpan(text: ' to get suggestions.'),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
