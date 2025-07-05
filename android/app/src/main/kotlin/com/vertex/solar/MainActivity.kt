package com.vertex.solar

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.util.Base64
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vertex.solar/search"
    private val FILE_CHANNEL = "com.vertex.solar/app"
    private val URL_CHANNEL = "app.channel.shared.data"
    private val SHORTCUTS_CHANNEL = "com.solar.browser/shortcuts"
    private var sharedUrl: String? = null
    private var initialUrl: String? = null

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
                "shareDownloadedFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    val fileName = call.argument<String>("fileName")
                    
                    if (path != null) {
                        try {
                            // Create FileProvider URI for the file
                            val file = File(path)
                            val fileUri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                file
                            )
                            
                            // Make the file visible to other apps via MediaScanner
                            MediaScannerConnection.scanFile(
                                context,
                                arrayOf(path),
                                arrayOf(mimeType)
                            ) { _, uri ->
                                Log.i(TAG, "File scanned: $uri")
                            }
                            
                            // Return success with the content URI
                            result.success(fileUri.toString())
                        } catch (e: Exception) {
                            Log.e(TAG, "Error sharing file: ${e.message}", e)
                            result.error("SHARE_ERROR", e.message, null)
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
        
        // PWA Shortcuts channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUTS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createShortcut" -> {
                    val url = call.argument<String>("url")
                    val title = call.argument<String>("title")
                    val favicon = call.argument<String>("favicon")
                    
                    if (url != null && title != null) {
                        createShortcut(url, title, favicon)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URL and title are required", null)
                    }
                }
                "deleteShortcut" -> {
                    val url = call.argument<String>("url")
                    
                    if (url != null) {
                        deleteShortcut(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URL is required", null)
                    }
                }
                "updateShortcut" -> {
                    val url = call.argument<String>("url")
                    val title = call.argument<String>("title")
                    val favicon = call.argument<String>("favicon")
                    
                    if (url != null && title != null) {
                        // For updating, we delete the old shortcut and create a new one
                        deleteShortcut(url)
                        createShortcut(url, title, favicon)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URL and title are required", null)
                    }
                }
                "getInitialUrl" -> {
                    result.success(initialUrl)
                    // Clear after sending to avoid reloading on app resume
                    initialUrl = null
                }
                else -> {
                    result.notImplemented()
                }
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
        
        // MediaStore channel for Android 10+ proper downloads handling
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vertex.solar/mediastore").setMethodCallHandler { call, result ->
            when (call.method) {
                "addToDownloads" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName") 
                    val mimeType = call.argument<String>("mimeType")
                    
                    if (filePath != null && fileName != null && mimeType != null) {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                // Android 10+ - Use MediaStore API
                                addToMediaStoreDownloads(filePath, fileName, mimeType)
                                result.success("File added to MediaStore Downloads")
                            } else {
                                // Android 9 and below - Use MediaScanner
                                MediaScannerConnection.scanFile(
                                    context,
                                    arrayOf(filePath),
                                    arrayOf(mimeType)
                                ) { _, uri ->
                                    result.success("File scanned: $uri")
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error adding to MediaStore: ${e.message}", e)
                            result.error("MEDIASTORE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "All arguments required", null)
                    }
                }
                "broadcastFileAdded" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            // Broadcast that a new file was added
                            val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                            intent.data = Uri.fromFile(File(path))
                            context.sendBroadcast(intent)
                            result.success("Broadcast sent")
                        } catch (e: Exception) {
                            result.error("BROADCAST_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
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
                        // Handle PWA URLs
                        if (uri.scheme == "pwa") {
                            val url = uri.toString()
                            Log.i(TAG, "Processing PWA URL: $url")
                            
                            // Extract the actual URL (remove pwa:// prefix)
                            val actualUrl = url.replaceFirst("pwa://", "")
                            
                            // For PWA intents, we want to always force showing PWA screen
                            // even if the app is already running, so we set a special flag
                            initialUrl = url
                            
                            if (flutterEngine != null) {
                                // Signal to Flutter to open the PWA view immediately
                                Log.i(TAG, "Opening PWA immediately: $url")
                                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, SHORTCUTS_CHANNEL)
                                    .invokeMethod("openPwaDirectly", actualUrl)
                            }
                        }
                        // Handle browser URLs
                        else if (uri.scheme == "http" || uri.scheme == "https") {
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
    
    private fun createShortcut(url: String, title: String, favicon: String?) {
        try {
            Log.d(TAG, "Creating shortcut for $title")
            Log.d(TAG, "Original URL: $url")
            Log.d(TAG, "Raw favicon URL: $favicon")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val shortcutManager = getSystemService(ShortcutManager::class.java)
                
                if (shortcutManager != null && shortcutManager.isRequestPinShortcutSupported) {
                    // Create the actual shortcut
                    val shortcutId = "pwa_${url.hashCode()}"
                    
                    // Create an intent that will open our app with the PWA URL
                    val pwaUrl = "pwa://$url"
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(pwaUrl))
                    intent.setPackage(packageName)
                    
                    // Build the shortcut
                    val shortcutInfoBuilder = ShortcutInfo.Builder(context, shortcutId)
                        .setShortLabel(title)
                        .setLongLabel(title)
                        .setIntent(intent)
                    
                    // Handle icon
                    var usedDefaultIcon = false
                    
                    // Add icon if available
                    if (!favicon.isNullOrEmpty()) {
                        try {
                            var iconBitmap: Bitmap? = null
                            
                            // Direct domain name approach
                            if (!favicon.startsWith("http") && !favicon.startsWith("data:")) {
                                Log.d(TAG, "Favicon appears to be a domain: $favicon")
                                val domain = favicon
                                iconBitmap = downloadIconFromDomain(domain)
                            }
                            // Special handling for ICO files
                            else if (favicon.endsWith(".ico") || favicon.contains("favicon.ico")) {
                                Log.d(TAG, "Favicon is an ICO file: $favicon")
                                
                                // Try direct domain approach for favicon.ico URLs
                                val uri = Uri.parse(if (url.startsWith("http")) url else "https://$url")
                                val domain = uri.host ?: ""
                                if (domain.isNotEmpty()) {
                                    iconBitmap = downloadIconFromDomain(domain)
                                }
                                
                                // If domain approach failed, try direct ICO download
                                if (iconBitmap == null) {
                                    iconBitmap = downloadIcon(favicon)
                                }
                            }
                            // Handle data URLs and direct image URLs
                            else {
                                iconBitmap = convertBase64ToBitmap(favicon)
                                
                                // For HTTPS URLs, try domain approach if direct conversion fails
                                if (iconBitmap == null && favicon.startsWith("https://")) {
                                    Log.d(TAG, "Direct conversion of HTTPS URL failed, trying domain extraction")
                                    val uri = Uri.parse(favicon)
                                    val domain = uri.host ?: ""
                                    if (domain.isNotEmpty()) {
                                        iconBitmap = downloadIconFromDomain(domain)
                                    }
                                }
                            }
                            
                            if (iconBitmap != null) {
                                Log.d(TAG, "Successfully created icon bitmap: ${iconBitmap.width}x${iconBitmap.height}")
                                shortcutInfoBuilder.setIcon(Icon.createWithBitmap(iconBitmap))
                            } else {
                                Log.e(TAG, "Failed to convert favicon to bitmap, using globe icon")
                                // Use globe icon instead of app icon
                                usedDefaultIcon = true
                                shortcutInfoBuilder.setIcon(Icon.createWithResource(context, 
                                    resources.getIdentifier("globe", "drawable", packageName)))
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error creating icon: ${e.message}", e)
                            // Use globe icon
                            usedDefaultIcon = true
                            shortcutInfoBuilder.setIcon(Icon.createWithResource(context, 
                                resources.getIdentifier("globe", "drawable", packageName)))
                        }
                    } else {
                        Log.d(TAG, "No favicon provided, using globe icon")
                        // Use globe icon
                        usedDefaultIcon = true
                        shortcutInfoBuilder.setIcon(Icon.createWithResource(context, 
                            resources.getIdentifier("globe", "drawable", packageName)))
                    }
                    
                    // If globe icon resource doesn't exist, fall back to app icon
                    if (usedDefaultIcon) {
                        try {
                            val resourceId = resources.getIdentifier("globe", "drawable", packageName)
                            if (resourceId == 0) {
                                Log.d(TAG, "Globe PNG icon not found, trying vector globe icon")
                                val vectorResourceId = resources.getIdentifier("ic_globe_hires", "drawable", packageName)
                                if (vectorResourceId == 0) {
                                    Log.d(TAG, "Vector globe icon not found, using app icon as fallback")
                                    shortcutInfoBuilder.setIcon(Icon.createWithResource(context, 
                                        resources.getIdentifier("ic_launcher", "mipmap", packageName)))
                                } else {
                                    shortcutInfoBuilder.setIcon(Icon.createWithResource(context, vectorResourceId))
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error using globe icon: ${e.message}", e)
                            shortcutInfoBuilder.setIcon(Icon.createWithResource(context, 
                                resources.getIdentifier("ic_launcher", "mipmap", packageName)))
                        }
                    }
                    
                    // Request pin shortcut
                    val shortcutInfo = shortcutInfoBuilder.build()
                    shortcutManager.requestPinShortcut(shortcutInfo, null)
                    
                    Log.d(TAG, "Shortcut created for $title ($url)")
                }
            } else {
                // For older Android versions
                createLegacyShortcut(url, title, favicon)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error creating shortcut: ${e.message}", e)
        }
    }
    
    // Download icon from Google's favicon service using domain
    private fun downloadIconFromDomain(domain: String): Bitmap? {
        try {
            Log.d(TAG, "Attempting to download icon using domain: $domain")
            // Google's favicon service always returns PNG
            val googleIconUrl = "https://www.google.com/s2/favicons?domain=$domain&sz=192"
            Log.d(TAG, "Using Google favicon URL: $googleIconUrl")
            
            val bitmap = downloadIcon(googleIconUrl)
            
            if (bitmap != null) {
                return bitmap
            }
            
            // Try DuckDuckGo as fallback
            val duckDuckGoUrl = "https://icons.duckduckgo.com/ip3/$domain.ico"
            Log.d(TAG, "Trying DuckDuckGo favicon service: $duckDuckGoUrl")
            return downloadIcon(duckDuckGoUrl)
        } catch (e: Exception) {
            Log.e(TAG, "Error downloading domain icon: ${e.message}", e)
            return null
        }
    }
    
    // Download icon from URL and convert to bitmap
    private fun downloadIcon(iconUrl: String): Bitmap? {
        try {
            Log.d(TAG, "Downloading icon from: $iconUrl")
            val url = URL(iconUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.doInput = true
            connection.setRequestProperty("User-Agent", 
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
            connection.connect()
            
            val contentType = connection.contentType
            Log.d(TAG, "Icon content type: $contentType")
            
            val inputStream = connection.inputStream
            val bitmap = BitmapFactory.decodeStream(inputStream)
            
            if (bitmap != null) {
                Log.d(TAG, "Successfully downloaded icon: ${bitmap.width}x${bitmap.height}")
                return resizeBitmap(bitmap, 192, 192)
            } else {
                Log.e(TAG, "Failed to decode downloaded icon")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error downloading icon: ${e.message}", e)
        }
        return null
    }

    private fun createLegacyShortcut(url: String, title: String, favicon: String?) {
        try {
            Log.d(TAG, "Creating legacy shortcut for $title with favicon")
            
            // Create an intent for our app
            val pwaUrl = "pwa://$url"
            val shortcutIntent = Intent(Intent.ACTION_VIEW, Uri.parse(pwaUrl))
            shortcutIntent.setPackage(packageName)
            
            // Create the shortcut intent
            val addIntent = Intent().apply {
                putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent)
                putExtra(Intent.EXTRA_SHORTCUT_NAME, title)
                
                // Set the icon
                if (!favicon.isNullOrEmpty()) {
                    try {
                        val iconBitmap = convertBase64ToBitmap(favicon)
                        if (iconBitmap != null) {
                            Log.d(TAG, "Successfully converted favicon to bitmap for legacy shortcut")
                            putExtra(Intent.EXTRA_SHORTCUT_ICON, iconBitmap)
                        } else {
                            Log.e(TAG, "Failed to convert favicon to bitmap for legacy shortcut, using default icon")
                            val iconResource = Intent.ShortcutIconResource.fromContext(
                                context, resources.getIdentifier("ic_launcher", "mipmap", packageName)
                            )
                            putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, iconResource)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error creating legacy icon: ${e.message}")
                        val iconResource = Intent.ShortcutIconResource.fromContext(
                            context, resources.getIdentifier("ic_launcher", "mipmap", packageName)
                        )
                        putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, iconResource)
                    }
                } else {
                    Log.d(TAG, "No favicon provided for legacy shortcut, using default icon")
                    val iconResource = Intent.ShortcutIconResource.fromContext(
                        context, resources.getIdentifier("ic_launcher", "mipmap", packageName)
                    )
                    putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, iconResource)
                }
                
                action = "com.android.launcher.action.INSTALL_SHORTCUT"
            }
            
            // Send the shortcut creation broadcast
            context.sendBroadcast(addIntent)
            
            Log.d(TAG, "Legacy shortcut created for $title ($url)")
        } catch (e: Exception) {
            Log.e(TAG, "Error creating legacy shortcut: ${e.message}")
        }
    }

    private fun convertBase64ToBitmap(faviconUrl: String?): Bitmap? {
        if (faviconUrl == null || faviconUrl.isEmpty()) {
            Log.d(TAG, "No favicon provided")
            return null
        }

        Log.d(TAG, "Converting favicon: $faviconUrl")
        
        try {
            // If it's a domain name (fallback), use Google's favicon service
            if (!faviconUrl.startsWith("http") && !faviconUrl.startsWith("data:")) {
                val domain = faviconUrl
                Log.d(TAG, "Using domain as fallback: $domain")
                val googleFaviconUrl = "https://www.google.com/s2/favicons?domain=$domain&sz=128"
                
                try {
                    val url = URL(googleFaviconUrl)
                    val connection = url.openConnection() as HttpURLConnection
                    connection.doInput = true
                    connection.connect()
                    val input = connection.inputStream
                    val bitmap = BitmapFactory.decodeStream(input)
                    if (bitmap != null) {
                        Log.d(TAG, "Successfully converted domain to bitmap using Google favicon service")
                        return resizeBitmap(bitmap, 192, 192)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error using Google favicon service for domain: ${e.message}", e)
                }
            }

            // Check if it's an ICO file URL - this seems to be our main issue
            if (faviconUrl.endsWith(".ico") || faviconUrl.contains("favicon.ico")) {
                Log.d(TAG, "ICO file detected, trying direct download first")
                
                try {
                    // First try direct download and conversion
                    val url = URL(faviconUrl)
                    val connection = url.openConnection() as HttpURLConnection
                    connection.doInput = true
                    // Add browser user agent to avoid server rejections
                    connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
                    connection.connect()
                    
                    val input = connection.inputStream
                    val bitmap = BitmapFactory.decodeStream(input)
                    
                    if (bitmap != null) {
                        Log.d(TAG, "Successfully converted ICO directly to bitmap: ${bitmap.width}x${bitmap.height}")
                        return resizeBitmap(bitmap, 192, 192)
                    } else {
                        Log.d(TAG, "Could not decode ICO directly, trying Google favicon service")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error downloading ICO directly: ${e.message}", e)
                    // Continue with Google favicon service
                }
                
                // Try Google favicon service as fallback
                try {
                    val url = URL(faviconUrl)
                    val domain = url.host
                    Log.d(TAG, "Extracted domain from ICO URL: $domain")
                    val googleFaviconUrl = "https://www.google.com/s2/favicons?domain=$domain&sz=128"
                    Log.d(TAG, "Using Google favicon service: $googleFaviconUrl")
                    
                    val googleUrl = URL(googleFaviconUrl)
                    val connection = googleUrl.openConnection() as HttpURLConnection
                    connection.doInput = true
                    connection.connect()
                    val input = connection.inputStream
                    val bitmap = BitmapFactory.decodeStream(input)
                    if (bitmap != null) {
                        Log.d(TAG, "Successfully converted ICO to bitmap using Google favicon service")
                        return resizeBitmap(bitmap, 192, 192)
                    } else {
                        Log.e(TAG, "Google favicon service returned null bitmap")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error using Google favicon service for ICO: ${e.message}", e)
                    // Continue with normal processing if this fails
                }
            }

            // Handle data URLs
            if (faviconUrl.startsWith("data:")) {
                Log.d(TAG, "Processing data URL, type: ${faviconUrl.substringBefore(";", "unknown")}")
                val base64Section = faviconUrl.substringAfter("base64,", "")
                
                if (base64Section.isNotEmpty()) {
                    try {
                        val decodedBytes = Base64.decode(base64Section, Base64.DEFAULT)
                        Log.d(TAG, "Decoded base64 data, length: ${decodedBytes.size} bytes")
                        val bitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
                        if (bitmap != null) {
                            Log.d(TAG, "Successfully converted data URL to bitmap: ${bitmap.width}x${bitmap.height}")
                            return resizeBitmap(bitmap, 192, 192)
                        } else {
                            Log.e(TAG, "Failed to decode base64 to bitmap despite having valid data")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error decoding base64 data: ${e.message}", e)
                    }
                } else {
                    Log.e(TAG, "No base64 data found in data URL")
                }
            } 
            // Handle direct image URLs
            else if (faviconUrl.startsWith("http")) {
                Log.d(TAG, "Processing direct URL: $faviconUrl")
                try {
                    val url = URL(faviconUrl)
                    val connection = url.openConnection() as HttpURLConnection
                    connection.doInput = true
                    // Add user agent to avoid server rejections
                    connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
                    connection.connect()
                    val contentType = connection.contentType
                    Log.d(TAG, "URL content type: $contentType")
                    val input = connection.inputStream
                    val bitmap = BitmapFactory.decodeStream(input)
                    if (bitmap != null) {
                        Log.d(TAG, "Successfully converted URL to bitmap: ${bitmap.width}x${bitmap.height}")
                        return resizeBitmap(bitmap, 192, 192)
                    } else {
                        Log.e(TAG, "Failed to decode URL to bitmap despite successful connection")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error downloading image from URL: ${e.message}", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error converting favicon: ${e.message}", e)
        }

        Log.d(TAG, "Using default icon as fallback - all conversion methods failed")
        return null
    }
    
    private fun resizeBitmap(bitmap: Bitmap, width: Int, height: Int): Bitmap {
        return Bitmap.createScaledBitmap(bitmap, width, height, true)
    }

    // Delete a shortcut from the home screen
    private fun deleteShortcut(url: String) {
        try {
            Log.d(TAG, "Deleting shortcut for URL: $url")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val shortcutManager = getSystemService(ShortcutManager::class.java)
                
                if (shortcutManager != null) {
                    // Create the shortcut ID using the same hash as in createShortcut
                    val shortcutId = "pwa_${url.hashCode()}"
                    
                    // Try to remove it from dynamic shortcuts if it exists there
                    shortcutManager.removeDynamicShortcuts(listOf(shortcutId))
                    
                    // For pinned shortcuts on Android 8+, we can't remove them directly
                    // We can only disable them, making them appear grayed out
                    shortcutManager.disableShortcuts(listOf(shortcutId), "Shortcut removed from app")
                    
                    Log.d(TAG, "Shortcut disabled: $shortcutId")
                }
            } else {
                // For older Android versions
                deleteLegacyShortcut(url)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting shortcut: ${e.message}", e)
        }
    }
    
    // Delete a legacy shortcut (Android 7.1 and below)
    private fun deleteLegacyShortcut(url: String) {
        try {
            Log.d(TAG, "Deleting legacy shortcut for URL: $url")
            
            // Create shortcut intent similar to when it was created
            val pwaUrl = "pwa://$url"
            val shortcutIntent = Intent(Intent.ACTION_VIEW, Uri.parse(pwaUrl))
            shortcutIntent.setPackage(packageName)
            
            // Create the removal intent
            val removeIntent = Intent().apply {
                putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent)
                // Note: We don't need to provide the exact same name used when creating
                // but we need an intent that matches
                putExtra(Intent.EXTRA_SHORTCUT_NAME, "")
                
                action = "com.android.launcher.action.UNINSTALL_SHORTCUT"
            }
            
            // Send the shortcut removal broadcast
            context.sendBroadcast(removeIntent)
            
            Log.d(TAG, "Legacy shortcut removal broadcast sent for: $url")
        } catch (e: Exception) {
            Log.e(TAG, "Error removing legacy shortcut: ${e.message}")
        }
    }

    // Helper method to add files to MediaStore Downloads for Android 10+
    private fun addToMediaStoreDownloads(filePath: String, fileName: String, mimeType: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val file = File(filePath)
                if (!file.exists()) {
                    Log.e(TAG, "File does not exist: $filePath")
                    return
                }

                // Determine the appropriate MediaStore collection
                val collection = when {
                    mimeType.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    mimeType.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    mimeType.startsWith("audio/") -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                    else -> MediaStore.Downloads.EXTERNAL_CONTENT_URI
                }

                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.SIZE, file.length())
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                    }
                }

                val contentResolver = context.contentResolver
                val uri = contentResolver.insert(collection, contentValues)

                if (uri != null) {
                    // Copy file content to MediaStore
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        FileInputStream(file).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }
                    
                    // Update the MediaStore entry to mark as complete
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        contentValues.clear()
                        contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                        contentResolver.update(uri, contentValues, null, null)
                    }
                    
                    Log.i(TAG, "File successfully added to MediaStore: $uri")
                } else {
                    Log.e(TAG, "Failed to create MediaStore entry")
                    // Fallback to media scanner
                    MediaScannerConnection.scanFile(
                        context,
                        arrayOf(filePath),
                        arrayOf(mimeType),
                        null
                    )
                }
            } catch (e: IOException) {
                Log.e(TAG, "IOException adding file to MediaStore: ${e.message}", e)
                // Fallback to media scanner
                MediaScannerConnection.scanFile(
                    context,
                    arrayOf(filePath),
                    arrayOf(mimeType),
                    null
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error adding file to MediaStore: ${e.message}", e)
                // Fallback to media scanner
                MediaScannerConnection.scanFile(
                    context,
                    arrayOf(filePath),
                    arrayOf(mimeType),
                    null
                )
            }
        }
    }
}