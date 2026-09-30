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
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return
        val source = when (sbn.packageName) {
            "com.tencent.mm" -> "wechat"
            "com.eg.android.AlipayGphone" -> "alipay"
            else -> return
        }
        if ((sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString() ?: ""
        // Conservative allowlist: ordinary chat text must not become an expense.
        if (title !in setOf("微信支付", "支付宝", "支付宝支付")) return
        if (!Regex("支付成功|付款成功|消费成功").containsMatchIn(text)) return
        if (Regex("退款|收款成功|收入|失败|待支付").containsMatchIn(text)) return
        val amountMatch = Regex("(?:[¥￥]\\s*|(?:支付成功|付款成功|消费成功)[:：]?\\s*)([0-9]+(?:,[0-9]{3})*(?:\\.[0-9]{1,2})?)(?![0-9.])")
            .find(text) ?: return
        val amount = amountMatch.groupValues[1].replace(",", "").toDoubleOrNull() ?: return
        if (!amount.isFinite() || amount <= 0) return
        val merchant = Regex("(?:商户|收款方)[:：]\\s*([^\\n，,]+)")
            .find(text)?.groupValues?.get(1)?.trim() ?: "未知商户"
        try {
            PaymentQueue.add(this, mapOf(
                "eventId" to "${sbn.key}:${sbn.postTime}",
                "source" to source, "amount" to amount,
                "merchantName" to merchant, "timestamp" to sbn.postTime
            ))
            channel?.invokeMethod("notificationsAvailable", null)
        } catch (e: Exception) {
            Log.e("FinanceNotifications", "Unable to persist or signal payment event")
        }
    }
}
