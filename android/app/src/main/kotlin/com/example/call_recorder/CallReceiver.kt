package com.example.call_recorder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log

class CallReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "CallReceiver"
        const val PREFS_NAME = "call_recorder_prefs"
        const val KEY_AUTO_RECORD = "auto_record"

        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var isIncoming = false
        private var savedNumber: String? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val autoRecord = prefs.getBoolean(KEY_AUTO_RECORD, true)

        if (!autoRecord) {
            Log.d(TAG, "Auto-record is disabled, ignoring call state change")
            return
        }

        val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        val state = when (stateStr) {
            TelephonyManager.EXTRA_STATE_IDLE -> TelephonyManager.CALL_STATE_IDLE
            TelephonyManager.EXTRA_STATE_OFFHOOK -> TelephonyManager.CALL_STATE_OFFHOOK
            TelephonyManager.EXTRA_STATE_RINGING -> TelephonyManager.CALL_STATE_RINGING
            else -> return
        }

        onCallStateChanged(context, state, number)
    }

    private fun onCallStateChanged(context: Context, state: Int, number: String?) {
        if (lastState == state) return

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                // Incoming call - ringing
                isIncoming = true
                savedNumber = number
                Log.d(TAG, "Incoming call ringing from: $number")
            }

            TelephonyManager.CALL_STATE_OFFHOOK -> {
                // Call answered or outgoing call started
                if (lastState == TelephonyManager.CALL_STATE_RINGING) {
                    // Incoming call answered
                    Log.d(TAG, "Incoming call answered from: $savedNumber")
                } else {
                    // Outgoing call
                    isIncoming = false
                    savedNumber = number
                    Log.d(TAG, "Outgoing call to: $number")
                }

                // Start recording
                startRecordingService(context)
            }

            TelephonyManager.CALL_STATE_IDLE -> {
                // Call ended
                if (lastState == TelephonyManager.CALL_STATE_OFFHOOK) {
                    // Was in a call, now ended - stop recording
                    Log.d(TAG, "Call ended, stopping recording")
                    stopRecordingService(context)
                }
                // Reset state
                isIncoming = false
                savedNumber = null
            }
        }

        lastState = state
    }

    private fun startRecordingService(context: Context) {
        val serviceIntent = Intent(context, CallRecordingService::class.java).apply {
            putExtra(CallRecordingService.EXTRA_PHONE_NUMBER, savedNumber ?: "Unknown")
            putExtra(CallRecordingService.EXTRA_CALL_TYPE, if (isIncoming) "incoming" else "outgoing")
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "Recording service started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording service: ${e.message}", e)
        }
    }

    private fun stopRecordingService(context: Context) {
        val serviceIntent = Intent(context, CallRecordingService::class.java)
        context.stopService(serviceIntent)
        Log.d(TAG, "Recording service stopped")
    }
}
