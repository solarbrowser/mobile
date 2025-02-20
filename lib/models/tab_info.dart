import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

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
  Uint8List? favicon;
  late WebViewController controller;
  final bool isIncognito;

  BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.isIncognito = false,
  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))  // Transparent background
      ..enableZoom(false)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
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