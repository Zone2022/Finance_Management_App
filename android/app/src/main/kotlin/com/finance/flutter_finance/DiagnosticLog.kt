package com.finance.flutter_finance

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Bounded local diagnostics: no notification contents, amounts, accounts or keys. */
object DiagnosticLog {
    private fun prefs(context: Context) = context.getSharedPreferences("diagnostic_log", Context.MODE_PRIVATE)
    @Synchronized fun add(context: Context, message: String) {
        val old = JSONArray(prefs(context).getString("entries", "[]"))
        val next = JSONArray()
        for (i in maxOf(0, old.length() - 199) until old.length()) next.put(old.getJSONObject(i))
        next.put(JSONObject().put("time", System.currentTimeMillis()).put("message", message))
        prefs(context).edit().putString("entries", next.toString()).commit()
    }
    @Synchronized fun list(context: Context): List<Map<String, Any>> {
        val entries = JSONArray(prefs(context).getString("entries", "[]"))
        return (0 until entries.length()).reversed().map { i ->
            val row = entries.getJSONObject(i)
            mapOf("time" to row.getLong("time"), "message" to row.getString("message"))
        }
    }
    @Synchronized fun clear(context: Context) { prefs(context).edit().remove("entries").commit() }
}
