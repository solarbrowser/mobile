package com.vertex.solar

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vertex.solar/search"
    private val FILE_CHANNEL = "com.vertex.solar/app"
    private val URL_CHANNEL = "app.channel.shared.data"
    private var sharedUrl: String? = null

    companion object {
        private const val TAG = "SolarBrowser"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // File operations channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(
                            context,
                            arrayOf(path),
                            null
                        ) { _, uri ->
                            result.success(uri?.toString())
                        }
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }
                "refreshMediaStore" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                            val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                            val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            intent.data = Uri.fromFile(downloadDir)
                            context.sendBroadcast(intent)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("REFRESH_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Search channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalizedStrings" -> {
                    result.success(mapOf(
                        "searchTheWeb" to "Search the web",
                        "recentSearches" to "Recent Searches"
                    ))
                }
                else -> result.notImplemented()
            }
        }
        
        // URL handling channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, URL_CHANNEL).setMethodCallHandler { call, result ->
            Log.i(TAG, "URL channel method call received: ${call.method}")
            
            when (call.method) {
                "getSharedUrl" -> {
                    Log.i(TAG, "getSharedUrl called, returning: $sharedUrl")
                    result.success(sharedUrl)
                }
                "confirmUrlLoaded" -> {
                    try {
                        val arguments = call.arguments as Map<*, *>
                        val url = arguments["url"] as String
                        val success = arguments["success"] as Boolean
                        
                        Log.i(TAG, "URL loading confirmation received: url=$url, success=$success")
                        
                        if (success && url == sharedUrl) {
                            Log.i(TAG, "URL loaded successfully, clearing sharedUrl")
                            sharedUrl = null
                        }
                        
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error handling confirmUrlLoaded: ${e.message}", e)
                        result.error("ERROR", "Failed to handle URL confirmation", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // If we have a pending URL and the engine is ready, send it after a short delay
        if (!sharedUrl.isNullOrEmpty()) {
            Log.i(TAG, "Have a shared URL to send: $sharedUrl")
            android.os.Handler().postDelayed({
                sendUrlToFlutter(flutterEngine, sharedUrl!!)
            }, 1000)
        }
    }
    
    private fun sendUrlToFlutter(flutterEngine: FlutterEngine, url: String) {
        Log.i(TAG, "Sending URL to Flutter: $url")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, URL_CHANNEL).invokeMethod(
            "loadUrl", 
            url, 
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.i(TAG, "Successfully sent URL to Flutter")
                }
                override fun error(code: String, message: String?, details: Any?) {
                    Log.e(TAG, "Error sending URL to Flutter: $message")
                    // Try again with delay
                    android.os.Handler().postDelayed({
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, URL_CHANNEL).invokeMethod("loadUrl", url)
                    }, 1500)
                }
                override fun notImplemented() {
                    Log.e(TAG, "Method not implemented")
                }
            }
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i(TAG, "MainActivity onCreate called")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.i(TAG, "onNewIntent called")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.w(TAG, "handleIntent: intent is null")
            return
        }
        
        Log.i(TAG, "handleIntent: action=${intent.action}, data=${intent.data}")
        
        try {
            when (intent.action) {
                Intent.ACTION_VIEW -> {
                    val uri = intent.data
                    if (uri != null) {
                        // Handle browser URLs
                        if (uri.scheme == "http" || uri.scheme == "https") {
                            val url = uri.toString()
                            Log.i(TAG, "Processing browser URL: $url")
                            sharedUrl = url
                            
                            // If Flutter engine is ready, send it now
                            if (flutterEngine != null) {
                                sendUrlToFlutter(flutterEngine!!, url)
                            } else {
                                Log.i(TAG, "Flutter engine not ready, URL will be sent when ready")
                            }
                        }
                        // Handle search URLs
                        else if (uri.scheme == "search") {
                            // Handle search:// URLs
                            val query = uri.schemeSpecificPart?.removePrefix("//")?.let { Uri.decode(it) }
                            if (!query.isNullOrEmpty()) {
                                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                                    .invokeMethod("openNewTabWithSearch", query)
                            }
                        }
                    } else {
                        Log.w(TAG, "ACTION_VIEW intent has null URI")
                    }
                }
                Intent.ACTION_MAIN -> {
                    // Handle explicit search intents
                    if (intent.getBooleanExtra("openNewTab", false)) {
                        intent.getStringExtra("searchQuery")?.let { query ->
                            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                                .invokeMethod("openNewTabWithSearch", query)
                        }
                    }
                }
                Intent.ACTION_SEND -> {
                    if (intent.type == "text/plain") {
                        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                        Log.i(TAG, "Processing ACTION_SEND text: $sharedText")
                        if (!sharedText.isNullOrEmpty()) {
                            if (sharedText.startsWith("http://") || sharedText.startsWith("https://")) {
                                sharedUrl = sharedText
                                if (flutterEngine != null) {
                                    sendUrlToFlutter(flutterEngine!!, sharedText)
                                }
                            } else {
                                // Handle non-URL text
                                if (flutterEngine != null) {
                                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                                        .invokeMethod("openNewTabWithSearch", sharedText)
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling intent: ${e.message}", e)
        }
    }
}