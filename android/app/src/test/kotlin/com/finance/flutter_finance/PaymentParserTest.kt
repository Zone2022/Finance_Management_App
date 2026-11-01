package com.finance.flutter_finance

import org.junit.Assert.*
import org.junit.Test

class PaymentParserTest {
    @Test fun recognizesScreenshotFormats() {
        assertEquals(1.00, PaymentParser.parse("com.tencent.mm", "Weixin Pay", "¥1.00 paid")!!.amount, 0.001)
        assertEquals(0.01, PaymentParser.parse("com.eg.android.AlipayGphone", "交易提醒", "你有一笔0.01元的支出，点此查看详情。")!!.amount, 0.001)
        assertEquals(0.01, PaymentParser.parse("com.chinamworld.main", "动账提醒", "您尾号1849的储蓄账户11月1日13时14分支出人民币0.01元。点击查看>>")!!.amount, 0.001)
    }

    @Test fun rejectsNonPaymentAndIncome() {
        assertNull(PaymentParser.parse("com.tencent.mm", "张三", "¥1.00 paid"))
        assertNull(PaymentParser.parse("com.tencent.mm", "Weixin Pay", "¥1.00 received"))
        assertNull(PaymentParser.parse("com.eg.android.AlipayGphone", "交易提醒", "你有一笔1.00元的收入"))
        assertNull(PaymentParser.parse("com.chinamworld.main", "动账提醒", "支出人民币0.01元退款"))
        assertNull(PaymentParser.parse("other.app", "Weixin Pay", "¥1.00 paid"))
    }
}
