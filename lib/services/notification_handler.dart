import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import 'classification_service.dart';

class NotificationHandler {
  static const _channel = MethodChannel('com.finance/notifications');
  static final NotificationHandler _instance = NotificationHandler._();
  factory NotificationHandler() => _instance;
  NotificationHandler._();
  bool _isListening = false;
  bool _draining = false;
  bool _requested = false;
  final ValueNotifier<String?> importError = ValueNotifier(null);
  AppLifecycleListener? _lifecycle;
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void startListening() {
    if (_isListening || !isSupported) return;
    _isListening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationsAvailable') await _drain();
    });
    _lifecycle = AppLifecycleListener(onResume: () => _drain());
    unawaited(_drain());
  }

  Future<void> openSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');

  Future<void> retryImport() => _drain();

  Future<List<dynamic>> getLogs() async =>
      await _channel.invokeListMethod<dynamic>('getLogs') ?? [];
  Future<Map<dynamic, dynamic>> listenerStatus() async =>
      await _channel.invokeMapMethod<dynamic, dynamic>('listenerStatus') ?? {};
  Future<void> clearLogs() => _channel.invokeMethod<void>('clearLogs');
  Future<void> addLog(String message) =>
      _channel.invokeMethod<void>('addLog', message);

  // Acknowledge only after the database transaction commits. One consumer.
  Future<void> _drain() async {
    _requested = true;
    if (_draining) return;
    _draining = true;
    try {
      while (_requested && _isListening) {
        _requested = false;
        final events =
            await _channel.invokeListMethod<dynamic>('getPendingPayments') ??
            [];
        importError.value = null;
        for (final event in events) {
          try {
            final args = Map<String, dynamic>.from(event as Map);
            final amount = (args['amount'] as num).toDouble();
            final source = args['source'] as String;
            final eventId = args['eventId'] as String;
            if (!amount.isFinite ||
                amount <= 0 ||
                !['wechat', 'alipay', 'bank'].contains(source) ||
                eventId.isEmpty) {
              throw const FormatException('Invalid payment event');
            }
            final merchant = args['merchantName'] as String;
            final category = await ClassificationService().classify(merchant);
            await DatabaseHelper().insertTransaction(
              Transaction(
                amount: amount,
                merchantName: merchant,
                category: category,
                source: source,
                eventId: eventId,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  args['timestamp'] as int,
                ),
              ),
            );
            await _channel.invokeMethod<void>('ackPayment', eventId);
            await addLog('支出已导入账本');
          } on FormatException {
            importError.value = '部分通知无法导入，请检查通知格式；其他通知会继续处理。';
            continue;
          } on TypeError {
            importError.value = '部分通知数据无效，其他通知会继续处理。';
            continue;
          }
        }
        if (events.isEmpty) importError.value = null;
      }
    } catch (_) {
      importError.value = '通知导入失败，请检查存储空间后重试。';
      try {
        await addLog('账本导入失败，待处理记录已保留');
      } catch (_) {}
      debugPrint('Payment import deferred; pending events retained on device.');
    } finally {
      _draining = false;
    }
  }

  void dispose() {
    _isListening = false;
    _channel.setMethodCallHandler(null);
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}
