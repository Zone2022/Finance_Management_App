class Transaction {
  final int? id;
  final double amount;
  final String merchantName;
  final String category;
  final String source; // 'wechat' or 'alipay'
  final DateTime timestamp;
  final String? note;
  final String? eventId;
  final bool isExpense;

  const Transaction({
    this.id,
    required this.amount,
    required this.merchantName,
    required this.category,
    required this.source,
    required this.timestamp,
    this.note,
    this.eventId,
    this.isExpense = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'merchant_name': merchantName,
      'category': category,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'event_id': eventId,
      'is_expense': isExpense ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      merchantName: map['merchant_name'] as String,
      category: map['category'] as String,
      source: map['source'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      note: map['note'] as String?,
      eventId: map['event_id'] as String?,
      isExpense: (map['is_expense'] as int) == 1,
    );
  }

  Transaction copyWith({
    int? id,
    double? amount,
    String? merchantName,
    String? category,
    String? source,
    DateTime? timestamp,
    String? note,
    bool? isExpense,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      eventId: eventId,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  @override
  String toString() =>
      'Transaction(amount: \$${amount.toStringAsFixed(2)}, merchant: $merchantName, category: $category)';
}
