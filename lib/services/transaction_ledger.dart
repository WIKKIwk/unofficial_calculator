import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/captured_notification.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';
import 'notification_transaction_parser.dart';

const _prefsTransactions = 'transactions_v1';

class TransactionLedger extends ChangeNotifier {
  TransactionLedger({
    NotificationTransactionParser? parser,
  }) : _parser = parser ?? const NotificationTransactionParser();

  final NotificationTransactionParser _parser;
  final List<TransactionRecord> _items = <TransactionRecord>[];
  final Set<String> _seen = <String>{};
  Timer? _persistDebounce;

  List<TransactionRecord> get items => List.unmodifiable(_items);

  TransactionSummary get summary => TransactionSummary.fromRecords(_items);

  Future<void> init() async {
    await _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsTransactions);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final parsed = <TransactionRecord>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          parsed.add(TransactionRecord.fromMap(decoded));
        } else if (decoded is Map) {
          parsed.add(TransactionRecord.fromMap(decoded.cast<String, dynamic>()));
        }
      } catch (_) {
        // Ignore malformed rows so a single bad record never blocks startup.
      }
    }

    if (parsed.isEmpty) {
      return;
    }

    _items
      ..clear()
      ..addAll(parsed);
    _rebuildSeen();
    notifyListeners();
  }

  Future<TransactionRecord?> ingestNotification(
    CapturedNotification notification,
  ) async {
    final record = _parser.parse(notification);
    if (record == null) {
      return null;
    }

    final signature = _signature(record);
    if (_seen.contains(signature)) {
      return null;
    }

    _seen.add(signature);
    _items.insert(0, record);
    while (_items.length > 1000) {
      final removed = _items.removeLast();
      _seen.remove(_signature(removed));
    }
    _schedulePersist();
    notifyListeners();
    return record;
  }

  Future<void> clear() async {
    _items.clear();
    _seen.clear();
    _schedulePersist();
    notifyListeners();
  }

  void _rebuildSeen() {
    _seen
      ..clear()
      ..addAll(_items.map(_signature));
  }

  String _signature(TransactionRecord record) {
    final bucket = record.receivedAt.millisecondsSinceEpoch ~/ 60000;
    return '${record.packageName.toLowerCase().trim()}|$bucket|${record.amount}|${record.rawTitle.toLowerCase().trim()}|${record.rawContent.toLowerCase().trim()}';
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_persistNow());
    });
  }

  Future<void> _persistNow() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _items.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_prefsTransactions, encoded);
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    unawaited(_persistNow());
    super.dispose();
  }
}

