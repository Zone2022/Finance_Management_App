/// A persisted substring rule. Longer keywords win; newer IDs break ties.
class MerchantRule {
  const MerchantRule({
    required this.id,
    required this.keyword,
    required this.category,
  });

  final int id;
  final String keyword;
  final String category;

  factory MerchantRule.fromMap(Map<String, Object?> row) => MerchantRule(
    id: row['id'] as int,
    keyword: row['keyword'] as String,
    category: row['category'] as String,
  );
}
