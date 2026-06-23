package org.finarus.finarus

import android.app.Notification
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class NotifCaptureService : NotificationListenerService() {

    companion object {
        private const val TAG = "NotifCapture"
        private val FINANCIAL_APPS = arrayOf(
            "com.dana", "gopay", "com.bca", "com.bni", "com.bri",
            "com.mandiri", "com.ovo", "com.linkaja", "com.shopeepay",
            "com.paypal", "com.ocbc", "com.seabank", "com.blu",
            "com.android.dana"
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val notification = sbn.notification ?: return
            val packageName = sbn.packageName.lowercase()

            val isFinancial = FINANCIAL_APPS.any { packageName.contains(it) }
            if (!isFinancial) return

            val text = extractText(notification) ?: return
            if (text.isBlank()) return

            val entry = JSONObject().apply {
                put("text", text)
                put("app", packageName)
                put("time", System.currentTimeMillis())
                put("title", notification.extras.getString(Notification.EXTRA_TITLE) ?: "")
            }

            saveCapture(entry)
            Log.d(TAG, "Captured from $packageName: ${text.take(60)}")
        } catch (e: Exception) {
            Log.e(TAG, "Error capturing notification: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}

    private fun extractText(notification: Notification): String? {
        val extras = notification.extras ?: return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            extras.getCharSequence(Notification.EXTRA_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
            extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
        }

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
        return if (text.isNotBlank()) text else title.takeIf { it.isNotBlank() }
    }

    private fun saveCapture(entry: JSONObject) {
        try {
            val file = File(cacheDir, "captured_notifs.json")
            val existing = if (file.exists()) {
                val content = file.readText()
                if (content.isNotBlank()) JSONArray(content) else JSONArray()
            } else {
                JSONArray()
            }

            existing.put(entry)

            // Keep only last 50
            val maxSize = 50
            while (existing.length() > maxSize) {
                existing.remove(0)
            }

            file.writeText(existing.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error saving capture: ${e.message}")
        }
    }
}
