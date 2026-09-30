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
        for (final event in events) {
          final args = Map<String, dynamic>.from(event as Map);
          final amount = (args['amount'] as num).toDouble();
          final source = args['source'] as String;
          final eventId = args['eventId'] as String;
          if (!amount.isFinite ||
              amount <= 0 ||
              !['wechat', 'alipay'].contains(source) ||
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
        }
      }
    } catch (_) {
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
