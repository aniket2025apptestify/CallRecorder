package com.example.call_recorder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device booted - call recorder ready to detect calls")
            // The CallReceiver is registered in the manifest,
            // so it will automatically start listening for phone state changes
            // No additional action needed here
        }
    }
}
