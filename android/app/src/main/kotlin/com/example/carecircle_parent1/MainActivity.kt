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

        // 🔹 App Icon + Name Method Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_INFO_CHANNEL
        ).setMethodCallHandler { call, result ->
            val packageName = call.argument<String>("packageName")
            if (packageName.isNullOrBlank()) {
                result.error("ERROR", "Package name missing", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "getAppIcon" -> {
                    val bytes = getAppIconBytes(packageName)
                    result.success(bytes)
                }
                "getAppInfo" -> {
                    val info = getAppInfo(packageName)
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun drawableToBitmap(drawable: android.graphics.drawable.Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            val icon = pm.getApplicationIcon(appInfo)
            val bitmap = drawableToBitmap(icon)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun getAppInfo(packageName: String): Map<String, Any?> {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            val appName = pm.getApplicationLabel(appInfo).toString()
            val iconBytes = getAppIconBytes(packageName) ?: ByteArray(0)

            mapOf(
                "name" to appName,
                "icon" to iconBytes
            )
        } catch (e: Exception) {
            mapOf(
                "name" to packageName,
                "icon" to ByteArray(0)
            )
        }
    }
}
