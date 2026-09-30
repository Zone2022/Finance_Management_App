package com.finance.flutter_finance

import android.content.Context
import org.json.JSONObject

/** Keep events without a Flutter engine; remove only after DB acknowledgement. */
object PaymentQueue {
    private fun preferences(context: Context) =
        context.getSharedPreferences("pending_payments", Context.MODE_PRIVATE)

    @Synchronized
    fun add(context: Context, payment: Map<String, Any>) {
        check(preferences(context).edit()
            .putString(payment["eventId"] as String, JSONObject(payment).toString()).commit())
    }

    @Synchronized
    fun pending(context: Context): List<Map<String, Any>> =
        preferences(context).all.values.map { raw ->
            val json = JSONObject(raw as String)
            mapOf(
                "eventId" to json.getString("eventId"),
                "source" to json.getString("source"),
                "amount" to json.getDouble("amount"),
                "merchantName" to json.getString("merchantName"),
                "timestamp" to json.getLong("timestamp")
            )
        }.sortedBy { it["timestamp"] as Long }

    @Synchronized
    fun acknowledge(context: Context, eventId: String) {
        check(preferences(context).edit().remove(eventId).commit())
    }
}
