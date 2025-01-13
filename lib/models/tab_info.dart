import 'package:webview_flutter/webview_flutter.dart';

class TabInfo {
  String title;
  String url;
  WebViewController controller;
  String? favicon;

  TabInfo({
    required this.title,
    required this.url,
    required this.controller,
    this.favicon,
  });
} 