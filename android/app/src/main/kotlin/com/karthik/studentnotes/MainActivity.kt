package com.karthik.studentnotes

import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL_SECURITY = "com.studentnotes/screen_security"
    private val CHANNEL_FILES = "com.karthik.studentnotes/files"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Screen security channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SECURITY)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureMode" -> {
                        enableSecureMode()
                        result.success(null)
                    }
                    "disableSecureMode" -> {
                        disableSecureMode()
                        result.success(null)
                    }
                    "isSecureModeEnabled" -> {
                        result.success(isSecureModeEnabled())
                    }
                    else -> result.notImplemented()
                }
            }
        
        // File opening channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_FILES)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openFile", "openFileWithContentUri" -> {
                        try {
                            val filePath = call.argument<String>("filePath")
                            val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                            
                            if (filePath != null) {
                                openFileWithContentUri(filePath, mimeType)
                                result.success("File opened successfully")
                            } else {
                                result.error("INVALID_ARGUMENT", "filePath is null", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to open file: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun enableSecureMode() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun disableSecureMode() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    private fun isSecureModeEnabled(): Boolean {
        return (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    }

    private fun openFileWithContentUri(filePath: String, mimeType: String) {
        val file = File(filePath)
        if (!file.exists()) {
            throw Exception("File does not exist: $filePath")
        }

        // Use FileProvider to get a content:// URI instead of file:// URI
        val contentUri: Uri = FileProvider.getUriForFile(
            this,
            "com.karthik.studentnotes.fileprovider",
            file
        )

        // Create intent to open the file
        val intent = Intent().apply {
            action = Intent.ACTION_VIEW
            setDataAndType(contentUri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Start the activity
        startActivity(intent)
    }
}
