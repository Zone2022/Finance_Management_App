import 'dart:async';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._() : _factory = null, _path = null;
  DatabaseHelper.forTesting(this._factory, this._path);
  final DatabaseFactory? _factory;
  final String? _path;

  Database? _database;
  Future<Database>? _opening;
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await (_opening ??= _initDatabase());
      return _database!;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _initDatabase() async {
    final factory = _factory ?? databaseFactory;
    final dbPath = _path == null ? await factory.getDatabasesPath() : '';
    final path = join(dbPath, 'finance.db');

    return await factory.openDatabase(
      _path ?? path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE transactions ADD COLUMN event_id TEXT',
            );
            await db.execute(
              'CREATE UNIQUE INDEX idx_transactions_event ON transactions(event_id)',
            );
          }
        },
      ),
    );
  }

  Future<void> close() async {
    final db = _database ?? await _opening;
    await db?.close();
    _database = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant_name TEXT NOT NULL,
        category TEXT NOT NULL,
        source TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT,
        event_id TEXT,
        is_expense INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE merchant_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX idx_transactions_event ON transactions(event_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_timestamp ON transactions(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category)',
    );
    await db.execute(
      'CREATE INDEX idx_merchant_rules_keyword ON merchant_rules(keyword)',
    );

    await _insertDefaults(db);
  }

  Future<void> _insertDefaults(Database db) async {
    for (final cat in Category.defaults) {
      await db.insert('categories', cat.toMap());
    }

    const rules = [
      {'keyword': '美团', 'category': '餐饮'},
      {'keyword': '饿了么', 'category': '餐饮'},
      {'keyword': '大众点评', 'category': '餐饮'},
      {'keyword': '肯德基', 'category': '餐饮'},
      {'keyword': '麦当劳', 'category': '餐饮'},
      {'keyword': '星巴克', 'category': '餐饮'},
      {'keyword': '瑞幸', 'category': '餐饮'},
      {'keyword': '奈雪', 'category': '餐饮'},
      {'keyword': '喜茶', 'category': '餐饮'},
      {'keyword': '滴滴', 'category': '交通'},
      {'keyword': '高德', 'category': '交通'},
      {'keyword': '铁路', 'category': '交通'},
      {'keyword': '航空', 'category': '交通'},
      {'keyword': '地铁', 'category': '交通'},
      {'keyword': '公交', 'category': '交通'},
      {'keyword': '加油', 'category': '交通'},
      {'keyword': '充电', 'category': '交通'},
      {'keyword': '淘宝', 'category': '购物'},
      {'keyword': '京东', 'category': '购物'},
      {'keyword': '拼多多', 'category': '购物'},
      {'keyword': '天猫', 'category': '购物'},
      {'keyword': '唯品会', 'category': '购物'},
      {'keyword': '得物', 'category': '购物'},
      {'keyword': '水电', 'category': '居住'},
      {'keyword': '房租', 'category': '居住'},
      {'keyword': '物业', 'category': '居住'},
      {'keyword': '燃气', 'category': '居住'},
      {'keyword': '暖气', 'category': '居住'},
      {'keyword': '腾讯视频', 'category': '娱乐'},
      {'keyword': '爱奇艺', 'category': '娱乐'},
      {'keyword': '网易云', 'category': '娱乐'},
      {'keyword': 'QQ音乐', 'category': '娱乐'},
      {'keyword': '电影院', 'category': '娱乐'},
      {'keyword': 'B站', 'category': '娱乐'},
      {'keyword': '哔哩哔哩', 'category': '娱乐'},
      {'keyword': '游戏', 'category': '娱乐'},
      {'keyword': '医院', 'category': '医疗'},
      {'keyword': '药店', 'category': '医疗'},
      {'keyword': '诊所', 'category': '医疗'},
      {'keyword': '挂号', 'category': '医疗'},
      {'keyword': '课程', 'category': '教育'},
      {'keyword': '培训', 'category': '教育'},
      {'keyword': '书本', 'category': '教育'},
      {'keyword': '学费', 'category': '教育'},
      {'keyword': '话费', 'category': '通讯'},
      {'keyword': '流量', 'category': '通讯'},
      {'keyword': '宽带', 'category': '通讯'},
    ];

    for (final rule in rules) {
      await db.insert('merchant_rules', rule);
    }
  }

  // ─── Transaction CRUD ───

  Future<int> insertTransaction(Transaction t) async {
    if (!t.amount.isFinite || t.amount <= 0) {
      throw ArgumentError.value(t.amount, 'amount', '必须为有限正数');
    }
    final db = await database;
    final id = await db.transaction((txn) async {
      if (t.eventId != null) {
        final existing = await txn.query(
          'transactions',
          columns: ['id'],
          where: 'event_id = ?',
          whereArgs: [t.eventId],
          limit: 1,
        );
        if (existing.isNotEmpty) return existing.first['id'] as int;
      }
      return txn.insert('transactions', t.toMap());
    });
    _changes.add(null);
    return id;
  }

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? source,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final conditions = <String>['1=1'];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('timestamp < ?');
      args.add(endDate.toIso8601String());
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    if (source != null) {
      conditions.add('source = ?');
      args.add(source);
    }

    final maps = await db.query(
      'transactions',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<int> updateTransaction(Transaction t) async {
    if (t.id == null || !t.amount.isFinite || t.amount <= 0) {
      throw ArgumentError('更新需要有效 ID 和有限正金额');
    }
    final db = await database;
    final count = await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
    if (count > 0) _changes.add(null);
    return count;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final count = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count > 0) _changes.add(null);
    return count;
  }

  // ─── Category CRUD ───

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  // ─── Aggregation ───

  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final conditions = <String>['is_expense = 1'];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('timestamp < ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE ${conditions.join(' AND ')}',
      args,
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getExpenseByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final conditions = <String>['is_expense = 1'];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('timestamp < ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE ${conditions.join(' AND ')} GROUP BY category',
      args,
    );

    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpense(int year) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT substr(timestamp, 1, 7) as month,
             SUM(amount) as total
      FROM transactions
      WHERE is_expense = 1 AND substr(timestamp, 1, 4) = ?
      GROUP BY month ORDER BY month
    ''',
      [year.toString()],
    );
  }

  Future<double> getDailyAverage({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final conditions = <String>['is_expense = 1'];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('timestamp < ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT substr(timestamp, 1, 10)) as days, COALESCE(SUM(amount), 0) as total FROM transactions WHERE ${conditions.join(' AND ')}',
      args,
    );

    final days = startDate != null && endDate != null
        ? DateTime.utc(endDate.year, endDate.month, endDate.day)
              .difference(
                DateTime.utc(startDate.year, startDate.month, startDate.day),
              )
              .inDays
        : (result.first['days'] as int?) ?? 0;
    final total = (result.first['total'] as num).toDouble();
    return days > 0 ? total / days : 0.0;
  }

  // ─── Merchant Rules ───

  Future<String?> matchCategory(String merchantName) async {
    final db = await database;
    final result = await db.query(
      'merchant_rules',
      where:
          'length(trim(keyword)) > 0 AND instr(lower(?), lower(keyword)) > 0',
      whereArgs: [merchantName],
      orderBy: 'length(keyword) DESC, id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['category'] as String : null;
  }

  Future<void> addMerchantRule(String keyword, String category) async {
    final db = await database;
    await db.insert('merchant_rules', {
      'keyword': keyword,
      'category': category,
    });
  }
}
