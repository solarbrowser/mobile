package com.vertex.solar

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vertex.solar/browser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    }
}