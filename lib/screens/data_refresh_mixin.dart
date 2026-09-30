import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';

/// Refresh persisted data after writes and when returning from the background.
mixin DataRefreshMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _subscription;
  late final AppLifecycleListener _lifecycle;
  int loadVersion = 0;
  String? loadError;

  Future<void> loadData();

  @override
  void initState() {
    super.initState();
    _subscription = context.read<DatabaseHelper>().changes.listen(
      (_) => loadData(),
    );
    _lifecycle = AppLifecycleListener(onResume: () => loadData());
    loadData();
  }

  Widget errorView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(loadError ?? '数据加载失败'),
        TextButton(onPressed: loadData, child: const Text('重试')),
      ],
    ),
  );

  @override
  void dispose() {
    _subscription?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }
}
