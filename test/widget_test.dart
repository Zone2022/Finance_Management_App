import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_finance/app.dart';
import 'package:flutter_finance/database/database_helper.dart';
import 'package:flutter_finance/models/transaction.dart';
import 'package:flutter_finance/screens/transactions_screen.dart';
import 'package:flutter_finance/widgets/monthly_bar_chart.dart';
import 'package:flutter_finance/widgets/trend_line_chart.dart';
import 'package:flutter_finance/widgets/expense_pie_chart.dart';

class FakeDatabase implements DatabaseHelper {
  final updates = StreamController<void>.broadcast();
  String? lastSource;
  bool fail = false;
  List<Transaction> rows = [];
  @override
  Stream<void> get changes => updates.stream;
  @override
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? source,
    int? limit,
    int? offset,
  }) async {
    if (fail) throw StateError('test database error');
    lastSource = source;
    return rows;
  }

  @override
  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
  }) async => 0;
  @override
  Future<double> getDailyAverage({
    DateTime? startDate,
    DateTime? endDate,
  }) async => 0;
  @override
  Future<Map<String, double>> getExpenseByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async => {};
  @override
  Future<List<Map<String, dynamic>>> getMonthlyExpense(int year) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeDatabase db;
  setUp(() {
    db = FakeDatabase();
  });
  tearDown(() => db.updates.close());
  Widget app(Widget child) =>
      Provider<DatabaseHelper>.value(value: db, child: child);

  testWidgets(
    'home shortcut navigates to transactions without private state access',
    (tester) async {
      await tester.pumpWidget(app(const FinanceApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('查看全部流水'));
      await tester.pumpAndSettle();
      expect(find.text('交易流水'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('source filter selects WeChat and can reset to all', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const MaterialApp(home: Scaffold(body: TransactionsScreen()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('微信').last);
    await tester.pumpAndSettle();
    expect(db.lastSource, 'wechat');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部来源').last);
    await tester.pumpAndSettle();
    expect(db.lastSource, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('database write refreshes empty view and income uses plus sign', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const MaterialApp(home: Scaffold(body: TransactionsScreen()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂无交易记录'), findsOneWidget);
    db.rows = [
      Transaction(
        amount: 12,
        merchantName: '测试收入',
        category: '其他',
        source: 'wechat',
        timestamp: DateTime(2026, 8),
        isExpense: false,
      ),
    ];
    db.updates.add(null);
    await tester.pumpAndSettle();
    expect(find.text('测试收入'), findsOneWidget);
    expect(find.text('+¥12.00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('database failure shows retry and can recover', (tester) async {
    db.fail = true;
    await tester.pumpWidget(
      app(const MaterialApp(home: Scaffold(body: TransactionsScreen()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('数据加载失败，请重试'), findsOneWidget);
    db.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('暂无交易记录'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('bar chart January is 1 and zero series has safe scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: MonthlyBarChart(
              data: [
                {'month': '2026-01', 'total': 0},
              ],
              year: 2026,
            ),
          ),
        ),
      ),
    );
    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(data.barGroups.first.x, 1);
    expect(data.barGroups.last.x, 12);
    expect(data.maxY, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'trend fills missing months with zero and pie ignores zero totals',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 220,
              child: TrendLineChart(
                data: [
                  {'month': '2026-02', 'total': 5},
                ],
              ),
            ),
          ),
        ),
      );
      final spots = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .single
          .spots;
      expect(spots.length, 12);
      expect(spots[0].y, 0);
      expect(spots[1].y, 5);
      await tester.pumpWidget(
        const MaterialApp(home: ExpensePieChart(data: {'其他': 0})),
      );
      expect(find.text('暂无数据'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
