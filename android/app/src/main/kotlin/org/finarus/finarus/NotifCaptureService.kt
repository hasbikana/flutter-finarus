package org.finarus.finarus

import android.app.Notification
import android.content.Context
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
        private const val DEDUP_WINDOW_MS = 30_000L

        private const val DEFAULT_FINANCIAL_APPS = "com.dana,id.dana,com.android.dana," +
                "com.gojek.gopay,com.gojek.app,gopay," +
                "ovo.id,com.ovo," +
                "com.linkaja,com.telkomsel.mytelkomsel," +
                "com.shopee.id,com.shopeepay," +
                "com.bca,com.bca.mobile.main," +
                "id.co.bni,id.co.bni.bnidirectmobile," +
                "com.bri,id.co.bri,com.bri.brizzi.mobile," +
                "com.bankmandiri,com.bankmandiri.mandirionline," +
                "com.paypal,com.paypal.android," +
                "com.ocbc,com.seabank,com.blu"

        private val recentCaptures = mutableListOf<Pair<Long, String>>()

        private fun getDetectedAppsFile(context: Context) = File(context.cacheDir, "detected_apps.json")
        private fun getAllowedAppsFile(context: Context) = File(context.cacheDir, "allowed_apps.json")
        private fun getCapturesFile(context: Context) = File(context.cacheDir, "captured_notifs.json")

        fun loadDetectedApps(context: Context): List<JSONObject> {
            return try {
                val file = getDetectedAppsFile(context)
                if (!file.exists()) return emptyList()
                val content = file.readText()
                if (content.isBlank()) return emptyList()
                val array = JSONArray(content)
                (0 until array.length()).map { array.getJSONObject(it) }
            } catch (e: Exception) {
                emptyList()
            }
        }

        fun saveDetectedApps(context: Context, apps: List<JSONObject>) {
            try {
                getDetectedAppsFile(context).writeText(JSONArray(apps).toString())
            } catch (e: Exception) {
                Log.e(TAG, "Error saving detected apps: ${e.message}")
            }
        }

        fun loadAllowedApps(context: Context): Set<String>? {
            return try {
                val file = getAllowedAppsFile(context)
                if (!file.exists()) return null
                val content = file.readText()
                if (content.isBlank()) return emptySet()
                val array = JSONArray(content)
                (0 until array.length()).map { array.getString(it) }.toSet()
            } catch (e: Exception) {
                null
            }
        }

        fun saveAllowedApps(context: Context, apps: Set<String>) {
            try {
                getAllowedAppsFile(context).writeText(JSONArray(apps.toList()).toString())
            } catch (e: Exception) {
                Log.e(TAG, "Error saving allowed apps: ${e.message}")
            }
        }

        private fun isDefaultFinancialApp(appId: String): Boolean {
            val defaults = DEFAULT_FINANCIAL_APPS.split(",").toSet()
            return defaults.any { appId.contains(it) }
        }

        fun isAppAllowed(context: Context, appId: String): Boolean {
            val allowed = loadAllowedApps(context)
            // If user hasn't configured yet, auto-allow default financial apps
            if (allowed == null) return isDefaultFinancialApp(appId)
            return allowed.contains(appId)
        }

        fun recordDetectedApp(context: Context, appId: String): Boolean {
            return try {
                val apps = loadDetectedApps(context).toMutableList()
                val existing = apps.find { it.optString("appId") == appId }

                if (existing == null) {
                    apps.add(JSONObject().apply {
                        put("appId", appId)
                        put("firstSeen", System.currentTimeMillis())
                        put("isNew", true)
                    })
                    saveDetectedApps(context, apps)
                    Log.d(TAG, "New app detected: $appId")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error recording detected app: ${e.message}")
                false
            }
        }

        fun getDetectedAppsWithStatus(context: Context): List<Map<String, Any>> {
            val allowed = loadAllowedApps(context)
            val apps = loadDetectedApps(context)
            return apps.map { app ->
                val appId = app.optString("appId")
                val isAllowed = when (allowed) {
                    null -> isDefaultFinancialApp(appId)
                    else -> allowed.contains(appId)
                }
                mapOf(
                    "appId" to appId,
                    "firstSeen" to app.optLong("firstSeen"),
                    "isNew" to app.optBoolean("isNew", false),
                    "allowed" to isAllowed
                )
            }
        }

        fun markAppsSeen(context: Context, appIds: List<String>) {
            try {
                val apps = loadDetectedApps(context).toMutableList()
                var changed = false
                for (app in apps) {
                    if (appIds.contains(app.optString("appId")) && app.optBoolean("isNew", false)) {
                        app.put("isNew", false)
                        changed = true
                    }
                }
                if (changed) saveDetectedApps(context, apps)
            } catch (e: Exception) {
                Log.e(TAG, "Error marking apps seen: ${e.message}")
            }
        }

        fun saveCapture(context: Context, entry: JSONObject) {
            try {
                val file = getCapturesFile(context)
                val existing = if (file.exists()) {
                    val content = file.readText()
                    if (content.isNotBlank()) JSONArray(content) else JSONArray()
                } else {
                    JSONArray()
                }

                existing.put(entry)

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

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val notification = sbn.notification ?: return
            val packageName = sbn.packageName.lowercase()
            val context = applicationContext

            // Skip our own app's notifications to avoid loops
            if (packageName == context.packageName) return

            // Always record this app as detected
            val isNewlyDetected = recordDetectedApp(context, packageName)

            val text = extractText(notification) ?: return
            if (text.isBlank()) return

            // Only capture if app is explicitly allowed
            if (!isAppAllowed(context, packageName)) {
                Log.d(TAG, "App $packageName not allowed, skipping capture")
                return
            }

            // Deduplicate: ignore exact same text+app within window
            val dedupKey = "$packageName:$text"
            val now = System.currentTimeMillis()
            synchronized(recentCaptures) {
                recentCaptures.removeAll { (timestamp, _) ->
                    now - timestamp > DEDUP_WINDOW_MS
                }
                if (recentCaptures.any { it.second == dedupKey }) {
                    Log.d(TAG, "Duplicate ignored from $packageName")
                    return
                }
                recentCaptures.add(now to dedupKey)
            }

            val entry = JSONObject().apply {
                put("text", text)
                put("app", packageName)
                put("time", now)
                put("title", notification.extras.getString(Notification.EXTRA_TITLE) ?: "")
                put("isNew", isNewlyDetected)
            }

            saveCapture(context, entry)
            Log.d(TAG, "Captured from $packageName: ${text.take(60)}")
        } catch (e: Exception) {
            Log.e(TAG, "Error capturing notification: ${e.message}", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}

    private fun extractText(notification: Notification): String? {
        val extras = notification.extras ?: return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
            extras.getCharSequence(Notification.EXTRA_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
            extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
            extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.let {
                if (it.isNotBlank()) return it.toString()
            }
        }

        // Fallback: combine title and text if both exist
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        return when {
            title.isNotBlank() && text.isNotBlank() -> "$title\n$text"
            text.isNotBlank() -> text
            title.isNotBlank() -> title
            else -> null
        }
    }
}
