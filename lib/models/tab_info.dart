import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart' as webview_flutter_android;
import 'package:flutter/material.dart';

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
  bool isIncognito = false;
  bool canGoBack = false;
  bool canGoForward = false;
  String? groupId;
  late WebViewController controller;

  BrowserTab({
    required this.id,
    required this.url,
    this.title = '',
    this.favicon,
    this.isIncognito = false,
    this.groupId,  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))  // Transparent background
      ..enableZoom(false)
      ..setUserAgent('Mozilla/9999.9999 (Linux; Android 9999; Solar 0.3.0) AppleWebKit/9999.9999 (KHTML, like Gecko) Chrome/9999.9999 Mobile Safari/9999.9999');
      // Enable file access for Android WebView
    if (controller.platform is webview_flutter_android.AndroidWebViewController) {
      (controller.platform as webview_flutter_android.AndroidWebViewController).setAllowFileAccess(true);
    }
    
    controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (isIncognito) {
              // Clear data after each page load in incognito mode
              controller.runJavaScript('''
                document.cookie.split(';').forEach(function(c) { 
                  document.cookie = c.replace(/^ +/, '').replace(/=.*/, '=;expires=' + new Date().toUTCString() + ';path=/'); 
                });
                document.querySelectorAll('input').forEach(function(input) {
                  input.autocomplete = 'off';
                  if (input.type === 'password') {
                    input.autocomplete = 'new-password';
                  }
                });
                try {
                  localStorage.clear();
                  sessionStorage.clear();
                } catch(e) {}
                var forms = document.getElementsByTagName('form');
                for(var i = 0; i < forms.length; i++) {
                  forms[i].autocomplete = 'off';
                }
              ''');
            }
          },
        ),
      );

    if (isIncognito) {
      controller
        ..clearCache()
        ..clearLocalStorage();
    }

    // Load the initial URL immediately
    if (url == 'about:blank') {
      controller.loadHtmlString('''
        <html>
          <head>
            <style>
              body { 
                background-color: transparent;
                margin: 0;
                padding: 0;
                height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
              }
            </style>
          </head>
          <body></body>
        </html>
      ''');
    } else {
      controller.loadRequest(Uri.parse(url));
    }
  }
} 