package com.iquxae.quikxchat

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BatteryOptimizationPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    companion object {
        private val PACKAGE_NAME_REGEX = Regex("^[a-zA-Z][a-zA-Z0-9_]*(?:\\.[a-zA-Z][a-zA-Z0-9_]*)*$")
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "battery_optimization")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isIgnoringBatteryOptimizations" -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                if (powerManager != null) {
                    val packageName = context.packageName
                    // Validate package name to prevent injection
                    if (packageName.matches(PACKAGE_NAME_REGEX)) {
                        result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.error("INVALID_PACKAGE", "Invalid package name format", null)
                    }
                } else {
                    result.error("SERVICE_UNAVAILABLE", "PowerManager service is not available", null)
                }
            }
            "requestIgnoreBatteryOptimizations" -> {
                try {
                    val packageName = context.packageName
                    // Validate package name to prevent injection
                    if (packageName.matches(PACKAGE_NAME_REGEX)) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        context.startActivity(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID_PACKAGE", "Invalid package name format", null)
                    }
                } catch (e: Exception) {
                    // Don't log exception details to prevent information disclosure
                    result.error("ERROR", "Failed to request battery optimization settings", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}