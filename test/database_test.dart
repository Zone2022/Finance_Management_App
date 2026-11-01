import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:flutter_finance/database/database_helper.dart';
import 'package:flutter_finance/models/transaction.dart';

Transaction payment(DateTime time, {String? eventId, double amount = 10}) =>
    Transaction(
      amount: amount,
      merchantName: '测试商户',
      category: '餐饮',
      source: 'wechat',
      timestamp: time,
      eventId: eventId,
    );

void main() {
  sqfliteFfiInit();
  late DatabaseHelper db;
  setUp(() {
    db = DatabaseHelper.forTesting(databaseFactoryFfi, inMemoryDatabasePath);
  });
  tearDown(() => db.close());

  test('concurrent initialization shares one database', () async {
    final handles = await Future.wait(List.generate(8, (_) => db.database));
    expect(handles.every((handle) => identical(handle, handles.first)), isTrue);
    expect((await db.getCategories()).length, 9);
  });

  test(
    'month end fractions are included, next month excluded; daily average uses calendar days',
    () async {
      final start = DateTime(2026, 8);
      final end = DateTime(2026, 9);
      await db.insertTransaction(
        payment(DateTime(2026, 8, 31, 23, 59, 59, 999), amount: 31),
      );
      await db.insertTransaction(payment(end, amount: 99));
      expect(await db.getTotalExpense(startDate: start, endDate: end), 31);
      expect(
        (await db.getTransactions(startDate: start, endDate: end)).length,
        1,
      );
      expect(await db.getExpenseByCategory(startDate: start, endDate: end), {
        '餐饮': 31.0,
      });
      expect(await db.getDailyAverage(startDate: start, endDate: end), 1);
    },
  );

  test('concurrent replay is idempotent, distinct event is retained', () async {
    final t = payment(DateTime(2026, 8, 1), eventId: 'event-1');
    final ids = await Future.wait(
      List.generate(5, (_) => db.insertTransaction(t)),
    );
    expect(ids.toSet().length, 1);
    await db.insertTransaction(payment(t.timestamp, eventId: 'event-2'));
    expect((await db.getTransactions()).length, 2);
  });

  test('invalid amounts rejected before persistence', () async {
    for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(
        db.insertTransaction(payment(DateTime.now(), amount: amount)),
        throwsArgumentError,
      );
    }
    expect(await db.getTransactions(), isEmpty);
  });

  test('cent totals remain exact through inserts and edits', () async {
    final time = DateTime(2026, 8, 1);
    for (var i = 0; i < 10; i++) {
      await db.insertTransaction(payment(time, amount: 0.1));
    }
    expect(await db.getTotalExpense(), 1.0);
    final first = (await db.getTransactions()).first;
    await db.updateTransaction(first.copyWith(amount: 0.25));
    expect(await db.getTotalExpense(), 1.15);
    await db.deleteTransaction(first.id!);
    expect(await db.getTotalExpense(), 0.9);
  });

  test('specific merchant rule wins and SQL wildcards are literal', () async {
    await db.addMerchantRule('美团买药', '医疗');
    expect(await db.matchCategory('美团买药旗舰店'), '医疗');
    await db.addMerchantRule('%', '购物');
    expect(await db.matchCategory('无匹配商户'), isNull);
  });

  test(
    'rules can be queried, edited and deleted without changing old transactions',
    () async {
      await db.createMerchantRule('测试商店', '购物');
      final rule = (await db.getMerchantRules()).firstWhere(
        (r) => r.keyword == '测试商店',
      );
      await db.insertTransaction(
        payment(DateTime(2026, 1)).copyWith(category: '购物'),
      );
      await db.updateMerchantRule(rule.id, '测试商店', '餐饮');
      expect(await db.matchCategory('测试商店旗舰店'), '餐饮');
      expect((await db.getTransactions()).single.category, '购物');
      await db.deleteMerchantRule(rule.id);
      expect(await db.matchCategory('测试商店旗舰店'), isNull);
      await expectLater(
        db.createMerchantRule('   ', '餐饮'),
        throwsArgumentError,
      );
    },
  );

  test(
    'v2 upgrade keeps transactions, category and merchant rules after restart',
    () async {
      final temp = await Directory.systemTemp.createTemp('finance_v2_upgrade_');
      final path = '${temp.path}/finance.db';
      DatabaseHelper? migrated;
      try {
        final old = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (database, _) async {
              await database.execute(
                'CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, merchant_name TEXT NOT NULL, category TEXT NOT NULL, source TEXT NOT NULL, timestamp TEXT NOT NULL, note TEXT, event_id TEXT, is_expense INTEGER NOT NULL DEFAULT 1)',
              );
              await database.execute(
                'CREATE UNIQUE INDEX idx_transactions_event ON transactions(event_id)',
              );
              await database.execute(
                'CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT NOT NULL, icon TEXT NOT NULL, color_value INTEGER NOT NULL)',
              );
              await database.execute(
                'CREATE TABLE merchant_rules (id INTEGER PRIMARY KEY, keyword TEXT NOT NULL, category TEXT NOT NULL)',
              );
              final map = payment(
                DateTime(2026, 8),
                amount: 12.34,
                eventId: 'old-payment',
              ).toMap()..remove('amount_fen');
              await database.insert('transactions', map);
              await database.insert('categories', {
                'id': 1,
                'name': '餐饮',
                'icon': '1',
                'color_value': 0,
              });
              await database.insert('merchant_rules', {
                'id': 7,
                'keyword': '旧商户',
                'category': '交通',
              });
            },
          ),
        );
        await old.close();
        migrated = DatabaseHelper.forTesting(databaseFactoryFfi, path);
        expect((await migrated.getTransactions()).single.amount, 12.34);
        expect((await migrated.getCategories()).single.name, '餐饮');
        expect(await migrated.matchCategory('旧商户付款'), '交通');
        expect(await migrated.getTotalExpense(), 12.34);
        await migrated.close();
        migrated = DatabaseHelper.forTesting(databaseFactoryFfi, path);
        expect(
          (await migrated.getTransactions()).single.eventId,
          'old-payment',
        );
        expect((await migrated.getMerchantRules()).single.keyword, '旧商户');
      } finally {
        await migrated?.close();
        await temp.delete(recursive: true);
      }
    },
  );

  test(
    'v1 migration preserves old rows and enables event deduplication',
    () async {
      final temp = await Directory.systemTemp.createTemp('finance_migration_');
      final path = '${temp.path}/finance.db';
      DatabaseHelper? migrated;
      try {
        final old = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (database, _) async {
              await database.execute(
                'CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, merchant_name TEXT NOT NULL, category TEXT NOT NULL, source TEXT NOT NULL, timestamp TEXT NOT NULL, note TEXT, is_expense INTEGER NOT NULL DEFAULT 1)',
              );
              final map = payment(DateTime(2026, 8)).toMap()
                ..remove('event_id')
                ..remove('amount_fen');
              await database.insert('transactions', map);
            },
          ),
        );
        await old.close();
        migrated = DatabaseHelper.forTesting(databaseFactoryFfi, path);
        expect((await migrated.getTransactions()).length, 1);
        final t = payment(DateTime(2026, 9), eventId: 'migrated');
        await migrated.insertTransaction(t);
        await migrated.insertTransaction(t);
        expect((await migrated.getTransactions()).length, 2);
      } finally {
        await migrated?.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
