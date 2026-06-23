package org.finarus.finarus

import android.content.Intent
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.finarus.finarus/share"
    private var sharedText: String? = null
    private var sharedImagePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handleIntent(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedData" -> {
                        val data = mutableMapOf<String, String>()
                        sharedText?.let { data["text"] = it }
                        sharedImagePath?.let { data["imagePath"] = it }
                        sharedText = null
                        sharedImagePath = null
                        result.success(data)
                    }
                    "getCapturedNotifications" -> {
                        val captures = readCapturedNotifications()
                        result.success(captures)
                    }
                    "openNotificationAccessSettings" -> {
                        openNotificationAccessSettings()
                        result.success(true)
                    }
                    "isNotificationListenerEnabled" -> {
                        result.success(isNotificationListenerEnabled())
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

    private fun readCapturedNotifications(): List<Map<String, Any>> {
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

            file.delete()
            result
        } catch (e: Exception) {
            emptyList()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent, isNewIntent = true)
    }

    private fun handleIntent(intent: Intent?, isNewIntent: Boolean = false) {
        if (intent?.action == Intent.ACTION_SEND) {
            val type = intent.type ?: ""
            when {
                type.startsWith("text/") -> {
                    sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                }
                type.startsWith("image/") -> {
                    val uri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                    if (uri != null) {
                        sharedImagePath = copyToCache(uri)?.absolutePath
                    }
                }
            }
            if (isNewIntent) {
                sendToFlutter()
            }
        }
    }

    private fun sendToFlutter() {
        val data = mutableMapOf<String, String>()
        sharedText?.let { data["text"] = it }
        sharedImagePath?.let { data["imagePath"] = it }
        if (data.isNotEmpty()) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("onShare", data)
            }
            sharedText = null
            sharedImagePath = null
        }
    }

    private fun copyToCache(uri: android.net.Uri): java.io.File? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val cacheDir = cacheDir
            val file = java.io.File(cacheDir, "shared_${System.currentTimeMillis()}.jpg")
            inputStream.use { input ->
                file.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            file
        } catch (e: Exception) {
            null
        }
    }
}
