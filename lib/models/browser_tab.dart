import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  final bool isIncognito;
  late WebViewController controller;

  BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.favicon,
    this.isIncognito = false,
  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      );
    
    if (url.isNotEmpty) {
      controller.loadRequest(Uri.parse(url));
    }
  }
} 