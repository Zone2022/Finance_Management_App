import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'database/database_helper.dart';
import 'services/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper();
  try {
    await db.database;
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('本地数据库无法打开，请检查设备存储后重试。'),
                TextButton(onPressed: main, child: Text('重试')),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  final notifier = NotificationHandler();
  notifier.startListening();

  runApp(Provider<DatabaseHelper>.value(value: db, child: const FinanceApp()));
}
