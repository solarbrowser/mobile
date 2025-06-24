import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_manager.dart';

class GeminiService {
  static const String _apiKey = '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _summariesKey = 'gemini_previous_summaries';
  static const int _maxSummaries = 50;

  static Future<String> summarizeText(String text, {bool isFullPage = false}) async {
    try {
      // Limit text length to avoid excessive token usage
      final truncatedText = text.length > 4000 ? text.substring(0, 4000) + '...' : text;
      
      // Get the current summary length preference
      final summaryLength = AIManager.getCurrentSummaryLength();
      String lengthInstruction;
      int maxOutputTokens;
      
      switch (summaryLength) {
        case SummaryLength.short:
          lengthInstruction = "Provide a brief summary in about 75 words";
          maxOutputTokens = 100;
          break;
        case SummaryLength.medium:
          lengthInstruction = "Provide a medium-length summary in about 150 words";
          maxOutputTokens = 200;
          break;
        case SummaryLength.long:
          lengthInstruction = "Provide a detailed summary in about 250 words";
          maxOutputTokens = 350;
          break;
        default:
          lengthInstruction = "Provide a medium-length summary in about 150 words";
          maxOutputTokens = 200;
      }

      // For very short text, adjust the prompt
      final prompt = text.length < 100 
        ? "Briefly describe what this text is about in a few sentences: $truncatedText"
        : (isFullPage 
            ? "$lengthInstruction of this webpage content, capturing the main points and key details:\n\n$truncatedText"
            : "$lengthInstruction of this text, capturing the main points:\n\n$truncatedText");

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'role': 'user',
            'parts': [{
              'text': prompt
            }]
          }],
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'candidateCount': 1,
            'maxOutputTokens': maxOutputTokens,
            'topP': 0.95
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed with status ${response.statusCode}: ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['candidates'] == null || jsonResponse['candidates'].isEmpty) {
        throw Exception('No response from AI');
      }

      final content = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
      if (content.isEmpty) {
        throw Exception('Empty response from AI');
      }      // Clean up the response by removing any "Assistant:" prefix
      final cleanContent = content.replaceAll(RegExp(r'^Assistant:\s*', caseSensitive: false), '').trim();
      
      return cleanContent;
    } catch (e) {
      debugPrint('Error summarizing text with Gemini: $e');
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
          'model': 'Gemini 2.0-Flash',
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
      'model': 'Gemini 2.0-Flash',
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
