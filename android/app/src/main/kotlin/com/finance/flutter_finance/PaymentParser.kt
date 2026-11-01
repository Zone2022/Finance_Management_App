package com.finance.flutter_finance

/** Only explicit debit notices from known payment apps are eligible. */
object PaymentParser {
    data class Payment(val source: String, val amount: Double, val merchant: String)

    fun parse(packageName: String, title: String, text: String): Payment? {
        val source = when (packageName) {
            "com.tencent.mm" -> "wechat"
            "com.eg.android.AlipayGphone" -> "alipay"
            "com.chinamworld.main" -> "bank"
            else -> return null
        }
        val content = "$title $text"
        if (Regex("退款|收款成功|收入|失败|待支付|refund|received|failed", RegexOption.IGNORE_CASE).containsMatchIn(content)) return null
        val amountPattern = when (source) {
            "wechat" -> {
                if (title !in setOf("微信支付", "Weixin Pay", "WeChat Pay")) return null
                if (!Regex("支付成功|付款成功|消费成功|\\bpaid\\b", RegexOption.IGNORE_CASE).containsMatchIn(text)) return null
                Regex("[¥￥]\\s*([0-9]+(?:,[0-9]{3})*(?:\\.[0-9]{1,2})?)(?![0-9.])")
            }
            "alipay" -> {
                if (title !in setOf("支付宝", "支付宝支付", "交易提醒")) return null
                Regex("(?:一笔\\s*)?([0-9]+(?:,[0-9]{3})*(?:\\.[0-9]{1,2})?)元的支出|[¥￥]\\s*([0-9]+(?:\\.[0-9]{1,2})?)")
            }
            else -> {
                if (title != "动账提醒" || !text.contains("支出人民币")) return null
                Regex("支出人民币\\s*([0-9]+(?:,[0-9]{3})*(?:\\.[0-9]{1,2})?)元")
            }
        }
        if (source == "alipay" && !Regex("支出|支付成功|付款成功|消费成功").containsMatchIn(text)) return null
        val match = amountPattern.find(text) ?: return null
        val raw = match.groupValues.drop(1).firstOrNull { it.isNotEmpty() } ?: return null
        val amount = raw.replace(",", "").toDoubleOrNull() ?: return null
        if (!amount.isFinite() || amount <= 0) return null
        val merchant = Regex("(?:商户|收款方)[:：]\\s*([^\\n，,]+)").find(text)?.groupValues?.get(1)?.trim() ?: "未知商户"
        return Payment(source, amount, merchant)
    }
}
