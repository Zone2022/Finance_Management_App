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

  test('specific merchant rule wins and SQL wildcards are literal', () async {
    await db.addMerchantRule('美团买药', '医疗');
    expect(await db.matchCategory('美团买药旗舰店'), '医疗');
    await db.addMerchantRule('%', '购物');
    expect(await db.matchCategory('无匹配商户'), isNull);
  });

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
                ..remove('event_id');
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
