package com.finance.flutter_finance

import android.content.Intent
import android.content.ComponentName
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NotificationListener.CHANNEL)
        NotificationListener.channel = channel
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getPendingPayments" -> result.success(PaymentQueue.pending(this))
                    "getLogs" -> result.success(DiagnosticLog.list(this))
                    "listenerStatus" -> {
                        val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: ""
                        val component = ComponentName(this, NotificationListener::class.java)
                        result.success(mapOf("authorized" to enabled.split(":").any { ComponentName.unflattenFromString(it) == component }, "connected" to NotificationListener.connected))
                    }
                    "clearLogs" -> { DiagnosticLog.clear(this); result.success(null) }
                    "addLog" -> { DiagnosticLog.add(this, call.arguments as String); result.success(null) }
                    "ackPayment" -> {
                        PaymentQueue.acknowledge(this, call.arguments as String)
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("PAYMENT_CHANNEL_ERROR", "通知操作失败，请重试", null)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        NotificationListener.channel?.setMethodCallHandler(null)
        NotificationListener.channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
