package com.example.call_recorder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.Environment
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
                        result.success(enabled)
                    }
                    "isAutoRecordEnabled" -> {
                        result.success(isAutoRecordEnabled())
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
        val dir = File(Environment.getExternalStorageDirectory(), CallRecordingService.RECORDING_DIR)
        if (!dir.exists()) dir.mkdirs()
        return dir.absolutePath
    }

    private fun getRecordingsList(): List<Map<String, Any>> {
        val dir = File(Environment.getExternalStorageDirectory(), CallRecordingService.RECORDING_DIR)
        if (!dir.exists()) return emptyList()

        return dir.listFiles()
            ?.filter { it.isFile && it.extension == "m4a" }
            ?.sortedByDescending { it.lastModified() }
            ?.map { file ->
                mapOf(
                    "file_path" to file.absolutePath,
                    "file_name" to file.name,
                    "file_size" to file.length(),
                    "last_modified" to file.lastModified()
                )
            } ?: emptyList()
    }

    private fun deleteRecording(filePath: String): Boolean {
        val file = File(filePath)
        return if (file.exists()) file.delete() else false
    }

    private fun setAutoRecord(enabled: Boolean) {
        val prefs = getSharedPreferences(CallReceiver.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(CallReceiver.KEY_AUTO_RECORD, enabled).apply()
    }

    private fun isAutoRecordEnabled(): Boolean {
        val prefs = getSharedPreferences(CallReceiver.PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(CallReceiver.KEY_AUTO_RECORD, true)
    }
}
