package com.solarbrowser.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private var sharedUrl: String? = null
    private val CHANNEL = "app.channel.shared.data"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Handle ACTION_VIEW intents (direct URL opens)
        if (intent.action == Intent.ACTION_VIEW) {
            sharedUrl = intent.dataString
        }
        // Handle ACTION_SEND intents (shared URLs)
        else if (intent.action == Intent.ACTION_SEND) {
            if (intent.type == "text/plain") {
                sharedUrl = intent.getStringExtra(Intent.EXTRA_TEXT)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    result.success(sharedUrl)
                    sharedUrl = null // Clear after sending
                }
                else -> result.notImplemented()
            }
        }
    }
} 