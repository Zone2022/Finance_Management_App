package com.finance.flutter_finance

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class NotificationListener : NotificationListenerService() {
    companion object {
        const val CHANNEL = "com.finance/notifications"
        var channel: MethodChannel? = null
        var connected = false
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        connected = true
        DiagnosticLog.add(this, "通知监听服务已连接")
    }

    override fun onListenerDisconnected() {
        connected = false
        DiagnosticLog.add(this, "通知监听服务已断开，请检查系统权限及后台限制")
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return
        val knownPackages = setOf("com.tencent.mm", "com.eg.android.AlipayGphone", "com.chinamworld.main")
        if (sbn.packageName !in knownPackages) return
        if ((sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString() ?: ""
        val payment = PaymentParser.parse(sbn.packageName, title, text)
        if (payment == null) {
            DiagnosticLog.add(this, "收到 ${sbn.packageName} 通知：未匹配支出格式")
            return
        }
        try {
            PaymentQueue.add(this, mapOf(
                "eventId" to "${sbn.key}:${sbn.postTime}",
                "source" to payment.source, "amount" to payment.amount,
                "merchantName" to payment.merchant, "timestamp" to sbn.postTime
            ))
            DiagnosticLog.add(this, "${sbn.packageName} 支出已加入待导入队列")
            channel?.invokeMethod("notificationsAvailable", null)
        } catch (e: Exception) {
            Log.e("FinanceNotifications", "Unable to persist or signal payment event")
            DiagnosticLog.add(this, "通知暂存或唤醒失败")
        }
    }
}
