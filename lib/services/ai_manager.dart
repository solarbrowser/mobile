import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'gemini_service.dart';

enum AIProvider {
  openai,
  gemini,
}

enum SummaryLength {
  short,  // 75 words
  medium, // 150 words
  long,   // 250 words
}

enum SummaryLanguage {
  english,
  turkish,
}

class AIManager {
  static const String _providerKey = 'ai_provider';
  static const String _summaryLengthKey = 'summary_length';
  static const String _summaryLanguageKey = 'summary_language';
  static AIProvider _currentProvider = AIProvider.gemini;
  static SummaryLength _summaryLength = SummaryLength.medium;
  static SummaryLanguage _summaryLanguage = SummaryLanguage.english;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load provider
    final providerStr = prefs.getString(_providerKey);
    if (providerStr != null) {
      _currentProvider = AIProvider.values.firstWhere(
        (e) => e.toString() == providerStr,
        orElse: () => AIProvider.gemini,
      );
    }

    // Load summary length
    final lengthStr = prefs.getString(_summaryLengthKey);
    if (lengthStr != null) {
      _summaryLength = SummaryLength.values.firstWhere(
        (e) => e.toString() == lengthStr,
        orElse: () => SummaryLength.medium,
      );
    }

    // Load summary language
    final languageStr = prefs.getString(_summaryLanguageKey);
    if (languageStr != null) {
      _summaryLanguage = SummaryLanguage.values.firstWhere(
        (e) => e.toString() == languageStr,
        orElse: () => SummaryLanguage.english,
      );
    }
    
    // Initialize OpenAI if needed
    if (_currentProvider == AIProvider.openai) {
      await AIService.initialize();
    }
  }

  static Future<String> summarizeText(String text, {bool isFullPage = false}) async {
    try {
      final int wordLimit = _getWordLimit();
      final truncatedText = text.length > 4000 ? text.substring(0, 4000) + '...' : text;

      // Create initial prompt with strict word count
      final String prompt = _createPrompt(truncatedText, isFullPage: isFullPage, wordLimit: wordLimit);

      // Get initial summary
      String summary;
      switch (_currentProvider) {
        case AIProvider.openai:
          summary = await AIService.summarizeText(prompt, isFullPage: isFullPage);
          break;
        case AIProvider.gemini:
          summary = await GeminiService.summarizeText(prompt, isFullPage: isFullPage);
          break;
      }

      // Count words and check if we need to adjust
      final words = summary.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      
      if (words.length < wordLimit * 0.8 || words.length > wordLimit * 1.2) {
        // If the length is off by more than 20%, try again with a more strict prompt
        final String retryPrompt = _createStrictPrompt(summary, wordLimit);
        String finalSummary;
        switch (_currentProvider) {
          case AIProvider.openai:
            finalSummary = await AIService.summarizeText(retryPrompt, isFullPage: false);
            break;
          case AIProvider.gemini:
            finalSummary = await GeminiService.summarizeText(retryPrompt, isFullPage: false);
            break;
        }
        
        // Ensure exact word count
        final finalWords = finalSummary.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (finalWords.length > wordLimit) {
          return finalWords.take(wordLimit).join(' ');
        }
        return finalSummary;
      }

      return summary;
    } catch (e) {
      if (_currentProvider == AIProvider.openai && 
          e.toString().toLowerCase().contains('quota')) {
        debugPrint('OpenAI quota exceeded, falling back to Gemini');
        return await GeminiService.summarizeText(text, isFullPage: isFullPage);
      }
      rethrow;
    }
  }

  static int _getWordLimit() {
    switch (_summaryLength) {
      case SummaryLength.short:
        return 75;
      case SummaryLength.medium:
        return 150;
      case SummaryLength.long:
        return 250;
    }
  }

  static String _createPrompt(String text, {required bool isFullPage, required int wordLimit}) {
    final String lengthPrompt = _summaryLanguage == SummaryLanguage.english
        ? "Create a summary in EXACTLY $wordLimit words. Not one word more or less. The summary must be exactly $wordLimit words:"
        : "Tam olarak $wordLimit kelimelik bir özet oluştur. Ne bir kelime fazla, ne bir kelime eksik. Özet kesinlikle $wordLimit kelime olmalı:";
    
    final String languagePrompt = _summaryLanguage == SummaryLanguage.english
        ? "The summary must be in English."
        : "Özet Türkçe olmalı.";

    final String contextPrompt = isFullPage
        ? (_summaryLanguage == SummaryLanguage.english
            ? "This is a webpage content. Extract and summarize the key points:"
            : "Bu bir web sayfası içeriğidir. Ana noktaları çıkarıp özetle:")
        : (_summaryLanguage == SummaryLanguage.english
            ? "This is a selected text. Provide a focused summary:"
            : "Bu seçili bir metindir. Odaklanmış bir özet oluştur:");

    return "$lengthPrompt\n$languagePrompt\n$contextPrompt\n\n$text";
  }

  static String _createStrictPrompt(String text, int wordLimit) {
    if (_summaryLanguage == SummaryLanguage.english) {
      return """
Rewrite the following summary to be EXACTLY $wordLimit words. Count carefully.
Current summary:

$text

Rules:
1. Output must be EXACTLY $wordLimit words
2. Maintain key information
3. Use complete sentences
4. Keep it coherent
5. Count each word carefully
""";
    } else {
      return """
Aşağıdaki özeti tam olarak $wordLimit kelime olacak şekilde yeniden yaz. Kelimeleri dikkatlice say.
Mevcut özet:

$text

Kurallar:
1. Çıktı tam olarak $wordLimit kelime olmalı
2. Önemli bilgileri koru
3. Tam cümleler kullan
4. Akıcı olsun
5. Her kelimeyi dikkatlice say
""";
    }
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> deleteSummary(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentProvider == AIProvider.openai ? 'previous_summaries' : 'gemini_previous_summaries';
    final summariesJson = prefs.getStringList(key) ?? [];
    
    if (index >= 0 && index < summariesJson.length) {
      summariesJson.removeAt(index);
      await prefs.setStringList(key, summariesJson);
    }
  }

  static Future<void> deleteAllSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentProvider == AIProvider.openai ? 'previous_summaries' : 'gemini_previous_summaries';
    await prefs.setStringList(key, []);
  }

  static Future<List<Map<String, dynamic>>> getPreviousSummaries() async {
    switch (_currentProvider) {
      case AIProvider.openai:
        return await AIService.getPreviousSummaries();
      case AIProvider.gemini:
        return await GeminiService.getPreviousSummaries();
    }
  }

  static Future<void> setProvider(AIProvider provider) async {
    _currentProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.toString());
    
    // Initialize OpenAI if switching to it
    if (provider == AIProvider.openai) {
      await AIService.initialize();
    }
  }

  static AIProvider getCurrentProvider() {
    return _currentProvider;
  }

  static Future<void> setSummaryLength(SummaryLength length) async {
    _summaryLength = length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryLengthKey, length.toString());
  }

  static Future<void> setSummaryLanguage(SummaryLanguage language) async {
    _summaryLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryLanguageKey, language.toString());
  }

  static SummaryLength getCurrentSummaryLength() {
    return _summaryLength;
  }

  static SummaryLanguage getCurrentSummaryLanguage() {
    return _summaryLanguage;
  }

  static Future<void> saveSummary(String summary, String url, String title) async {
    switch (_currentProvider) {
      case AIProvider.openai:
        await AIService.saveSummary(summary, url, title);
        break;
      case AIProvider.gemini:
        await GeminiService.saveSummary(summary, url, title);
        break;
    }
  }
}