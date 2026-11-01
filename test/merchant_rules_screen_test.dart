import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_finance/database/database_helper.dart';
import 'package:flutter_finance/models/merchant_rule.dart';
import 'package:flutter_finance/screens/merchant_rules_screen.dart';

class RuleDatabase implements DatabaseHelper {
  List<MerchantRule> rules = [
    const MerchantRule(id: 1, keyword: '美团', category: '餐饮'),
  ];
  @override
  Future<List<MerchantRule>> getMerchantRules() async => List.of(rules);
  @override
  Future<void> createMerchantRule(String keyword, String category) async {
    rules.add(MerchantRule(id: 2, keyword: keyword, category: category));
  }

  @override
  Future<int> updateMerchantRule(
    int id,
    String keyword,
    String category,
  ) async {
    rules = rules
        .map(
          (r) => r.id == id
              ? MerchantRule(id: id, keyword: keyword, category: category)
              : r,
        )
        .toList();
    return 1;
  }

  @override
  Future<int> deleteMerchantRule(int id) async {
    rules.removeWhere((r) => r.id == id);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('search, edit, create and delete merchant rules', (tester) async {
    final db = RuleDatabase();
    await tester.pumpWidget(
      Provider<DatabaseHelper>.value(
        value: db,
        child: const MaterialApp(home: MerchantRulesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '搜索关键词或分类'), '美团');
    expect(find.widgetWithText(ListTile, '美团'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, '美团'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '商户关键词'), '美团外卖');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(db.rules.first.keyword, '美团外卖');
    await tester.enterText(find.widgetWithText(TextField, '搜索关键词或分类'), '');
    await tester.tap(find.byTooltip('新增规则'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '商户关键词'), '测试店');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('测试店'), findsOneWidget);
    await tester.tap(find.byTooltip('删除 测试店'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.text('测试店'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
