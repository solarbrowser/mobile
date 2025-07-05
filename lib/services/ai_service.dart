import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  // Replace with your OpenAI API key from https://platform.openai.com/api-keys
  static const String _apiKey = '';
  static const String _summariesKey = 'previous_summaries';
  static const int _maxSummaries = 50;
  
  static Future<void> initialize() async {
    OpenAI.apiKey = _apiKey;
    OpenAI.organization = ""; // Add if you have an organization ID
  }

  static Future<String> summarizeText(String text, {bool isFullPage = false}) async {
    try {
      // Limit text length to avoid excessive token usage
      final truncatedText = text.length > 4000 ? text.substring(0, 4000) + '...' : text;

      final prompt = isFullPage 
        ? "Provide a comprehensive summary of this webpage content in 4-5 sentences, capturing the main points and key details:\n\n$truncatedText"
        : "Provide a detailed summary of this text in 2-3 sentences, capturing the main points:\n\n$truncatedText";

      final response = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "You are a helpful assistant that provides very concise summaries. Keep responses short and focused."
              )
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
            ],
          ),
        ],
        maxTokens: 250,
        temperature: 0.7,
      );

      if (response.choices.isEmpty) {
        throw Exception('No response from AI');
      }

      final contentItems = response.choices.first.message.content;
      if (contentItems == null || contentItems.isEmpty) {
        throw Exception('Empty response from AI');
      }      final content = contentItems.map((item) => item.text).join(' ').trim();
      if (content.isEmpty) {
        throw Exception('Empty text content from AI');
      }

      return content;
    } catch (e) {
      final error = e.toString().toLowerCase();
      if (error.contains('quota') || error.contains('exceeded') || error.contains('429')) {
        throw Exception('API quota exceeded. Please check your OpenAI account billing and limits at https://platform.openai.com/account/billing');
      }
      // debugPrint('Error summarizing text: $e');
      throw Exception('Failed to summarize text: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>> getPreviousSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getStringList(_summariesKey) ?? [];
    final List<Map<String, dynamic>> results = [];
    
    for (final item in summariesJson) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        results.add(decoded);
      } catch (e) {
        // If the item is not valid JSON, treat it as plain text
        results.add({
          'text': item,
          'date': DateTime.now().toIso8601String(),
          'model': 'GPT-3.5 Turbo',
          'language': 'English'
        });
      }
    }
    
    return results;
  }
  static Future<void> saveSummary(String summary, [String? url, String? title]) async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getStringList(_summariesKey) ?? [];
    
    String siteName = 'Unknown Site';
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        siteName = title?.isNotEmpty == true ? title! : uri.host.replaceFirst('www.', '');
      } catch (e) {
        siteName = title ?? 'Unknown Site';
      }
    } else if (title?.isNotEmpty == true) {
      siteName = title!;
    }
    
    // Create new summary with timestamp
    final newSummary = {
      'text': summary,
      'date': DateTime.now().toIso8601String(),
      'model': 'GPT-3.5 Turbo',
      'language': 'English',
      'url': url ?? '',
      'siteName': siteName,
    };
    
    // Add new summary at the beginning
    summariesJson.insert(0, jsonEncode(newSummary));
    
    // Keep only the last _maxSummaries
    if (summariesJson.length > _maxSummaries) {
      summariesJson.removeRange(_maxSummaries, summariesJson.length);
    }
    
    await prefs.setStringList(_summariesKey, summariesJson);
  }
} 
