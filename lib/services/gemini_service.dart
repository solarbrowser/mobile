import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKey = '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _summariesKey = 'gemini_previous_summaries';
  static const int _maxSummaries = 50;

  static Future<String> summarizeText(String text, {bool isFullPage = false}) async {
    try {
      // Limit text length to avoid excessive token usage
      final truncatedText = text.length > 4000 ? text.substring(0, 4000) + '...' : text;

      // For very short text, adjust the prompt
      final prompt = text.length < 100 
        ? "Briefly describe what this text is about: $truncatedText"
        : (isFullPage 
            ? "Provide a comprehensive summary of this webpage content in 4-5 sentences, capturing the main points and key details:\n\n$truncatedText"
            : "Provide a detailed summary of this text in 2-3 sentences, capturing the main points:\n\n$truncatedText");

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
            'maxOutputTokens': 250,
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
      }

      // Clean up the response by removing any "Assistant:" prefix
      final cleanContent = content.replaceAll(RegExp(r'^Assistant:\s*', caseSensitive: false), '').trim();
      
      await saveSummary(cleanContent);
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

  static Future<void> saveSummary(String summary) async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getStringList(_summariesKey) ?? [];
    
    // Create new summary with timestamp
    final newSummary = {
      'text': summary,
      'date': DateTime.now().toIso8601String(),
      'model': 'Gemini 2.0-Flash',
      'language': 'English'
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
