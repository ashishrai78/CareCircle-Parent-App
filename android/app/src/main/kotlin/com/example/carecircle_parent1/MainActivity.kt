package com.example.carecircle_parent1

import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val APP_INFO_CHANNEL = "app_info_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔹 Used App Icon + Name Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_INFO_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getAppInfo") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val info = getAppInfo(packageName)
                    result.success(info)
                } else {
                    result.error("ERROR", "Package name missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // 🔹 Used Apps Icon Logic
    private fun getAppInfo(packageName: String): Map<String, Any> {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            val appName = pm.getApplicationLabel(appInfo).toString()
            val icon = pm.getApplicationIcon(appInfo)

            val stream = ByteArrayOutputStream()
            val bitmap = (icon as BitmapDrawable).bitmap
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)

            mapOf(
                "name" to appName,
                "icon" to stream.toByteArray()
            )
        } catch (e: Exception) {
            mapOf(
                "name" to packageName,
                "icon" to ByteArray(0)
            )
        }
    }
}
