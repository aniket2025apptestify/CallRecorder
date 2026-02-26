package com.example.call_recorder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.Environment
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.example.call_recorder/recording"
        const val EVENT_CHANNEL = "com.example.call_recorder/events"
    }

    private var eventSink: EventChannel.EventSink? = null

    private val recordingCompleteReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.example.call_recorder.RECORDING_COMPLETE") {
                val data = mapOf(
                    "file_path" to (intent.getStringExtra("file_path") ?: ""),
                    "phone_number" to (intent.getStringExtra("phone_number") ?: "Unknown"),
                    "call_type" to (intent.getStringExtra("call_type") ?: "unknown"),
                    "duration" to intent.getIntExtra("duration", 0),
                    "file_size" to intent.getLongExtra("file_size", 0),
                    "audio_source" to (intent.getStringExtra("audio_source") ?: "UNKNOWN"),
                    "timestamp" to intent.getLongExtra("timestamp", System.currentTimeMillis())
                )
                eventSink?.success(data)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getRecordings" -> {
                            result.success(getRecordingsList())
                        }
                        "deleteRecording" -> {
                            val filePath = call.argument<String>("file_path")
                            if (filePath != null) {
                                val deleted = deleteRecording(filePath)
                                result.success(deleted)
                            } else {
                                result.error("INVALID_ARG", "file_path is required", null)
                            }
                        }
                        "toggleAutoRecord" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: true
                            setAutoRecord(enabled)
                            Log.d("MainActivity", "toggleAutoRecord: success setting to $enabled")
                            result.success(true) // Return true to indicate success
                        }
                        "isAutoRecordEnabled" -> {
                            val isEnabled = isAutoRecordEnabled()
                            Log.d("MainActivity", "isAutoRecordEnabled: returning $isEnabled")
                            result.success(isEnabled)
                        }
                        "getRecordingPath" -> {
                            result.success(getRecordingPath())
                        }
                        "isRecording" -> {
                            result.success(CallRecordingService.isRecording)
                        }
                        "getCurrentAudioSource" -> {
                            result.success(CallRecordingService.currentAudioSource)
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error in method channel: ${e.message}", e)
                    result.error("EXCEPTION", e.message, null)
                }
            }

        // Event Channel for real-time updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        // Register broadcast receiver
        val filter = IntentFilter("com.example.call_recorder.RECORDING_COMPLETE")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(recordingCompleteReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(recordingCompleteReceiver, filter)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(recordingCompleteReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun getRecordingPath(): String {
        val rootDir = Environment.getExternalStorageDirectory()
        val dir = File(rootDir, CallRecordingService.RECORDING_DIR)
        if (!dir.exists()) {
            if (!dir.mkdirs()) {
                return File(getExternalFilesDir(null), CallRecordingService.RECORDING_DIR).apply { if (!exists()) mkdirs() }.absolutePath
            }
        }
        return dir.absolutePath
    }

    private fun getRecordingsList(): List<Map<String, Any>> {
        val recordings = mutableListOf<Map<String, Any>>()
        
        // Check main directory
        val mainDir = File(Environment.getExternalStorageDirectory(), CallRecordingService.RECORDING_DIR)
        if (mainDir.exists()) {
            mainDir.listFiles()?.filter { it.isFile && it.extension == "m4a" }?.forEach { file ->
                recordings.add(mapOf(
                    "file_path" to file.absolutePath,
                    "file_name" to file.name,
                    "file_size" to file.length(),
                    "last_modified" to file.lastModified()
                ))
            }
        }
        
        // Check fallback directory
        val fallbackDir = File(getExternalFilesDir(null), CallRecordingService.RECORDING_DIR)
        if (fallbackDir.exists()) {
            fallbackDir.listFiles()?.filter { it.isFile && it.extension == "m4a" }?.forEach { file ->
                // Avoid duplicates if paths overlap (unlikely but safe)
                if (recordings.none { it["file_path"] == file.absolutePath }) {
                    recordings.add(mapOf(
                        "file_path" to file.absolutePath,
                        "file_name" to file.name,
                        "file_size" to file.length(),
                        "last_modified" to file.lastModified()
                    ))
                }
            }
        }

        return recordings.sortedByDescending { it["last_modified"] as Long }
    }

    private fun deleteRecording(filePath: String): Boolean {
        val file = File(filePath)
        return if (file.exists()) file.delete() else false
    }

    private fun setAutoRecord(enabled: Boolean) {
        val prefs = getSharedPreferences(CallReceiver.PREFS_NAME, Context.MODE_PRIVATE)
        Log.d("MainActivity", "Setting auto-record to: $enabled")
        prefs.edit().putBoolean(CallReceiver.KEY_AUTO_RECORD, enabled).commit()
    }

    private fun isAutoRecordEnabled(): Boolean {
        val prefs = getSharedPreferences(CallReceiver.PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(CallReceiver.KEY_AUTO_RECORD, true)
    }
}
