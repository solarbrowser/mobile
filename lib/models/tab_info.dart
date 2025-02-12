import 'package:webview_flutter/webview_flutter.dart';

class BookmarkItem {
  final String title;
  final String url;
  final String? favicon;

  BookmarkItem({
    required this.title,
    required this.url,
    this.favicon,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'favicon': favicon,
    };
  }

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      title: json['title'] as String,
      url: json['url'] as String,
      favicon: json['favicon'] as String?,
    );
  }
}

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  late WebViewController controller;

  BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.favicon,
  });
} 