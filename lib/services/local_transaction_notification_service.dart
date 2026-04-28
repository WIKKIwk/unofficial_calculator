import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/transaction_record.dart';

class LocalTransactionNotificationService {
  LocalTransactionNotificationService._();

  static final LocalTransactionNotificationService instance =
      LocalTransactionNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<void> showTransactionPrompt(TransactionRecord record) async {
    await init();
    final granted = await ensurePermission();
    if (!granted) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'transaction_followups',
      'Transaction follow-ups',
      channelDescription: 'Asks the user what a debit transaction was for.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await _plugin.show(
      id: _notificationId(record),
      title: 'Bu xarajat nimaga ketdi?',
      body: _buildBody(record),
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  int _notificationId(TransactionRecord record) {
    final raw = record.id.hashCode ^ record.receivedAt.millisecondsSinceEpoch;
    return raw & 0x7fffffff;
  }

  String _buildBody(TransactionRecord record) {
    final merchant = record.merchantName?.trim();
    final amount = record.amount.round().toString();
    final parts = <String>[amount, record.currency];
    if (merchant != null && merchant.isNotEmpty) {
      parts.add(merchant);
    }
    return '${parts.join(' · ')}. Qaysi xarajat edi?';
  }
}
