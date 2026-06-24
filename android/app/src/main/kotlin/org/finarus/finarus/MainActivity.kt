package org.finarus.finarus

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.finarus.finarus/share"
    private val TAG = "FinarusShare"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine, action=${intent?.action} type=${intent?.type}")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapturedNotifications" -> {
                        val captures = readCapturedNotifications(deleteAfterRead = true)
                        result.success(captures)
                    }
                    "peekCapturedNotifications" -> {
                        val captures = readCapturedNotifications(deleteAfterRead = false)
                        result.success(captures)
                    }
                    "openNotificationAccessSettings" -> {
                        openNotificationAccessSettings()
                        result.success(true)
                    }
                    "isNotificationListenerEnabled" -> {
                        result.success(isNotificationListenerEnabled())
                    }
                    "getDetectedApps" -> {
                        result.success(NotifCaptureService.getDetectedAppsWithStatus(this@MainActivity))
                    }
                    "setAllowedApps" -> {
                        val appIds = call.argument<List<String>>("appIds") ?: emptyList()
                        NotifCaptureService.saveAllowedApps(this@MainActivity, appIds.toSet())
                        result.success(true)
                    }
                    "resolveAppName" -> {
                        val appId = call.argument<String>("appId") ?: ""
                        result.success(resolveAppName(appId))
                    }
                    "markAppsSeen" -> {
                        val appIds = call.argument<List<String>>("appIds") ?: emptyList()
                        NotifCaptureService.markAppsSeen(this@MainActivity, appIds)
                        result.success(true)
                    }
                    "resolveSharedFile" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString == null) {
                            result.error("INVALID_URI", "URI is null", null)
                        } else {
                            val resolved = resolveSharedFile(uriString)
                            if (resolved != null) {
                                result.success(resolved)
                            } else {
                                result.error("COPY_FAILED", "Failed to copy shared file to cache", null)
                            }
                        }
                    }
                }
            }
        }
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return flat.contains(packageName)
    }

    private fun resolveAppName(appId: String): String? {
        return try {
            val appInfo = packageManager.getApplicationInfo(appId, 0)
            packageManager.getApplicationLabel(appInfo)?.toString()
        } catch (e: Exception) {
            null
        }
    }

    private fun readCapturedNotifications(deleteAfterRead: Boolean): List<Map<String, Any>> {
        return try {
            val file = File(cacheDir, "captured_notifs.json")
            if (!file.exists()) return emptyList()

            val content = file.readText()
            if (content.isBlank()) return emptyList()

            val jsonArray = JSONArray(content)
            val result = mutableListOf<Map<String, Any>>()

            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                result.add(mapOf(
                    "text" to obj.optString("text"),
                    "app" to obj.optString("app"),
                    "time" to obj.optLong("time")
                ))
            }

            if (deleteAfterRead) {
                file.delete()
            }
            result
        } catch (e: Exception) {
            emptyList()
        }
    }

    /// Menyalin file dari URI (content:// atau file://) ke cache app.
    /// Return path file di cache, atau null jika gagal.
    private fun resolveSharedFile(uriString: String): String? {
        return try {
            val uri = Uri.parse(uriString)
            val inputStream = when (uri.scheme) {
                "content", "file" -> contentResolver.openInputStream(uri)
                else -> File(uriString).inputStream()
            } ?: return null

            val ext = when (contentResolver.getType(uri)) {
                "image/png" -> "png"
                "image/webp" -> "webp"
                "image/gif" -> "gif"
                else -> "jpg"
            }
            val file = File(cacheDir, "shared_${System.currentTimeMillis()}.$ext")

            inputStream.use { input ->
                file.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            Log.d(TAG, "resolveSharedFile: copied $uriString -> ${file.absolutePath}")
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "resolveSharedFile error: ${e.message}")
            null
        }
    }
}
