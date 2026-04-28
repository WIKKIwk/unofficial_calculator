import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/captured_notification.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';
import '../models/transaction_types.dart';
import 'gemini_transaction_ai_service.dart';
import 'notification_transaction_parser.dart';
import 'transaction_feedback_store.dart';

const _prefsTransactions = 'transactions_v1';

class TransactionLedger extends ChangeNotifier {
  TransactionLedger({
    NotificationTransactionParser? parser,
    TransactionFeedbackStore? feedbackStore,
  }) : _parser = parser ??
            NotificationTransactionParser(
              feedbackStore: feedbackStore,
            ),
        _feedbackStore = feedbackStore;

  final NotificationTransactionParser _parser;
  final TransactionFeedbackStore? _feedbackStore;
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
    {
    String? geminiApiKey,
    String model = GeminiTransactionAiService.defaultModel,
  }) async {
    final record = await _parser.parse(
      notification,
      geminiApiKey: geminiApiKey,
      model: model,
    );
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

  TransactionRecord? findById(String id) {
    for (final record in _items) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  Future<void> updateCategory(
    String id,
    TransactionCategory category,
  ) async {
    final index = _items.indexWhere((record) => record.id == id);
    if (index == -1) {
      return;
    }
    final current = _items[index];
    _items[index] = TransactionRecord(
      id: current.id,
      receivedAt: current.receivedAt,
      packageName: current.packageName,
      rawTitle: current.rawTitle,
      rawContent: current.rawContent,
      amount: current.amount,
      currency: current.currency,
      direction: current.direction,
      category: current.category,
      confidence: current.confidence,
      userCategory: category,
      merchantName: current.merchantName,
      balanceAfter: current.balanceAfter,
      cardLast4: current.cardLast4,
      hints: current.hints,
    );
    _schedulePersist();
    notifyListeners();
  }

  Future<void> rememberFeedback(TransactionRecord record) async {
    final store = _feedbackStore;
    if (store == null) {
      return;
    }
    await store.rememberCategory(
      packageName: record.packageName,
      merchantName: record.merchantName,
      category: record.effectiveCategory,
    );
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
