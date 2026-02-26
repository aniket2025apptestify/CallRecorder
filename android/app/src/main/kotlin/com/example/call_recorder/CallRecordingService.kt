package com.example.call_recorder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class CallRecordingService : Service() {

    companion object {
        const val TAG = "CallRecordingService"
        const val CHANNEL_ID = "call_recording_channel"
        const val NOTIFICATION_ID = 1001
        const val EXTRA_PHONE_NUMBER = "phone_number"
        const val EXTRA_CALL_TYPE = "call_type"
        const val RECORDING_DIR = "callrecording"

        var isRecording = false
            private set
        var currentAudioSource = "UNKNOWN"
            private set
        var currentFilePath: String? = null
            private set
    }

    private var mediaRecorder: MediaRecorder? = null
    private var outputFile: String? = null
    private var phoneNumber: String = "Unknown"
    private var callType: String = "unknown"
    private var recordingStartTime: Long = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        phoneNumber = intent?.getStringExtra(EXTRA_PHONE_NUMBER) ?: "Unknown"
        callType = intent?.getStringExtra(EXTRA_CALL_TYPE) ?: "unknown"

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        startRecording()

        return START_STICKY
    }

    override fun onDestroy() {
        stopRecording()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Call Recording",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Notification shown while recording a call"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording Call")
            .setContentText("Recording call with $phoneNumber")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun startRecording() {
        try {
            val dir = File(
                Environment.getExternalStorageDirectory(),
                RECORDING_DIR
            )
            if (!dir.exists()) {
                dir.mkdirs()
            }

            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val cleanNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
            val fileName = "call_${cleanNumber}_${timestamp}.m4a"
            outputFile = File(dir, fileName).absolutePath
            currentFilePath = outputFile

            // Try VOICE_CALL first for both-side recording
            var audioSource = MediaRecorder.AudioSource.VOICE_CALL
            currentAudioSource = "VOICE_CALL"

            try {
                mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    MediaRecorder(this)
                } else {
                    @Suppress("DEPRECATION")
                    MediaRecorder()
                }

                mediaRecorder?.apply {
                    setAudioSource(audioSource)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                    setAudioEncodingBitRate(128000)
                    setAudioSamplingRate(44100)
                    setOutputFile(outputFile)
                    prepare()
                    start()
                }

                isRecording = true
                recordingStartTime = System.currentTimeMillis()
                Log.d(TAG, "Recording started with VOICE_CALL source: $outputFile")

            } catch (e: Exception) {
                Log.w(TAG, "VOICE_CALL failed, falling back to MIC: ${e.message}")
                
                // Fallback to MIC
                mediaRecorder?.release()
                mediaRecorder = null
                currentAudioSource = "MIC"
                audioSource = MediaRecorder.AudioSource.MIC

                mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    MediaRecorder(this)
                } else {
                    @Suppress("DEPRECATION")
                    MediaRecorder()
                }

                mediaRecorder?.apply {
                    setAudioSource(audioSource)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                    setAudioEncodingBitRate(128000)
                    setAudioSamplingRate(44100)
                    setOutputFile(outputFile)
                    prepare()
                    start()
                }

                isRecording = true
                recordingStartTime = System.currentTimeMillis()
                Log.d(TAG, "Recording started with MIC source (fallback): $outputFile")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording: ${e.message}", e)
            isRecording = false
            currentAudioSource = "FAILED"
            stopSelf()
        }
    }

    private fun stopRecording() {
        try {
            if (isRecording) {
                mediaRecorder?.apply {
                    stop()
                    release()
                }
                mediaRecorder = null
                isRecording = false

                val duration = ((System.currentTimeMillis() - recordingStartTime) / 1000).toInt()
                val file = File(outputFile ?: "")
                val fileSize = if (file.exists()) file.length() else 0L

                Log.d(TAG, "Recording stopped. Duration: ${duration}s, Size: ${fileSize}B, Source: $currentAudioSource")

                // Send broadcast to notify Flutter about new recording
                val broadcastIntent = Intent("com.example.call_recorder.RECORDING_COMPLETE").apply {
                    putExtra("file_path", outputFile)
                    putExtra("phone_number", phoneNumber)
                    putExtra("call_type", callType)
                    putExtra("duration", duration)
                    putExtra("file_size", fileSize)
                    putExtra("audio_source", currentAudioSource)
                    putExtra("timestamp", recordingStartTime)
                }
                sendBroadcast(broadcastIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording: ${e.message}", e)
        } finally {
            mediaRecorder?.release()
            mediaRecorder = null
            isRecording = false
            currentFilePath = null
        }
    }
}
