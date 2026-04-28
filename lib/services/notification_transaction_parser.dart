import '../models/captured_notification.dart';
import '../models/transaction_record.dart';
import '../models/transaction_types.dart';
import '../utils/finance_app_heuristic.dart' show matchesFinanceHeuristic;
import 'transaction_classifier.dart';

class NotificationTransactionParser {
  const NotificationTransactionParser({
    TransactionClassifier? classifier,
  }) : _classifier = classifier ?? const TransactionClassifier();

  final TransactionClassifier _classifier;

  TransactionRecord? parse(CapturedNotification notification) {
    final title = notification.title?.trim() ?? '';
    final content = notification.content?.trim() ?? '';
    final packageName = notification.packageName.trim();
    if (packageName.isEmpty) {
      return null;
    }

    final classification = _classifier.classify(
      title: title,
      content: content,
      packageName: packageName,
    );

    if (!_shouldKeep(notification, classification)) {
      return null;
    }

    final amount = classification.amount;
    if (amount == null || amount <= 0) {
      return null;
    }

    return TransactionRecord(
      id: _signature(notification, amount),
      receivedAt: notification.receivedAt,
      packageName: packageName,
      rawTitle: title,
      rawContent: content,
      amount: amount,
      currency: classification.currency,
      direction: classification.direction,
      category: classification.category,
      confidence: classification.confidence,
      merchantName: classification.merchantName,
      balanceAfter: classification.balanceAfter,
      cardLast4: classification.cardLast4,
      hints: classification.hints,
    );
  }

  bool _shouldKeep(
    CapturedNotification notification,
    TransactionClassification classification,
  ) {
    final title = notification.title ?? '';
    final content = notification.content ?? '';
    if (matchesFinanceHeuristic(title, notification.packageName) ||
        matchesFinanceHeuristic(content, notification.packageName)) {
      return true;
    }
    if (classification.amount != null &&
        classification.direction != TransactionDirection.unknown) {
      return true;
    }
    return _moneyKeywordMatch('$title $content'.toLowerCase());
  }

  bool _moneyKeywordMatch(String text) {
    for (final keyword in _moneyKeywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  String _signature(CapturedNotification notification, double amount) {
    final packageName = notification.packageName.toLowerCase().trim();
    final title = (notification.title ?? '').toLowerCase().trim();
    final content = (notification.content ?? '').toLowerCase().trim();
    final bucket = notification.receivedAt.millisecondsSinceEpoch ~/ 60000;
    return '$packageName|$bucket|$amount|$title|$content';
  }

  static const _moneyKeywords = <String>[
    'so\'m',
    'som',
    'uzs',
    'usd',
    'eur',
    'rub',
    'to\'lov',
    'tolov',
    'payment',
    'transfer',
    'yechildi',
    'debited',
    'withdrawn',
    'tushdi',
    'keldi',
    'refund',
    'qaytdi',
    'komissiya',
  ];
}

