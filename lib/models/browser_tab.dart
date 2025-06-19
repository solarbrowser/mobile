import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart' as webview_flutter_android;

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  final bool isIncognito;
  String? groupId;
  late WebViewController controller;

  BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.favicon,
    this.isIncognito = false,
    this.groupId,  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent);
      // Enable file access for Android WebView
    if (controller.platform is webview_flutter_android.AndroidWebViewController) {
      (controller.platform as webview_flutter_android.AndroidWebViewController).setAllowFileAccess(true);
    }
    
    controller.setNavigationDelegate(
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