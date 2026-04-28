import '../models/captured_notification.dart';
import '../models/transaction_record.dart';
import '../models/transaction_types.dart';
import '../utils/finance_app_heuristic.dart' show matchesFinanceHeuristic;
import 'gemini_transaction_ai_service.dart';
import 'transaction_feedback_store.dart';
import 'transaction_classifier.dart';

class NotificationTransactionParser {
  const NotificationTransactionParser({
    GeminiTransactionAiService? aiService,
    TransactionClassifier? classifier,
    TransactionFeedbackStore? feedbackStore,
  })  : _aiService = aiService ?? const GeminiTransactionAiService(),
        _classifier = classifier ?? const TransactionClassifier(),
        _feedbackStore = feedbackStore;

  final GeminiTransactionAiService _aiService;
  final TransactionClassifier _classifier;
  final TransactionFeedbackStore? _feedbackStore;

  Future<TransactionRecord?> parse(
    CapturedNotification notification, {
    String? geminiApiKey,
    String model = GeminiTransactionAiService.defaultModel,
  }) async {
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

    final apiKey = geminiApiKey?.trim();
    final shouldAskAi = apiKey != null &&
        apiKey.isNotEmpty &&
        (classification.amount == null || classification.confidence < 0.74);

    GeminiTransactionAnalysis? ai;
    if (shouldAskAi) {
      ai = await _aiService.analyze(
        apiKey: apiKey,
        title: title,
        content: content,
        packageName: packageName,
        model: model,
      );
    }

    final amount = ai?.amount ?? classification.amount;
    if (amount == null || amount <= 0) {
      return null;
    }

    final heuristicRecord = TransactionRecord(
      id: _signature(notification, amount),
      receivedAt: notification.receivedAt,
      packageName: packageName,
      rawTitle: title,
      rawContent: content,
      amount: amount,
      currency: ai?.currency ?? classification.currency,
      direction: classification.direction,
      category: classification.category,
      confidence: classification.confidence,
      merchantName: classification.merchantName,
      balanceAfter: classification.balanceAfter,
      cardLast4: classification.cardLast4,
      hints: classification.hints,
    );

    final overriddenRecord = _applyStoredFeedback(heuristicRecord);

    if (ai == null || !ai.isTransaction) {
      return overriddenRecord;
    }

    return _merge(overriddenRecord, ai);
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

  TransactionRecord _merge(
    TransactionRecord heuristic,
    GeminiTransactionAnalysis ai,
  ) {
    final aiDirection = _directionFromName(ai.direction);
    final aiCategory = _categoryFromName(ai.category);
    return TransactionRecord(
      id: heuristic.id,
      receivedAt: heuristic.receivedAt,
      packageName: heuristic.packageName,
      rawTitle: heuristic.rawTitle,
      rawContent: heuristic.rawContent,
      amount: ai.amount ?? heuristic.amount,
      currency: ai.currency.isEmpty ? heuristic.currency : ai.currency,
      direction: aiDirection == TransactionDirection.unknown
          ? heuristic.direction
          : aiDirection,
      category: aiCategory == TransactionCategory.other
          ? heuristic.category
          : aiCategory,
      confidence: ai.confidence > heuristic.confidence
          ? ai.confidence
          : heuristic.confidence,
      merchantName: ai.merchantName ?? heuristic.merchantName,
      balanceAfter: ai.balanceAfter ?? heuristic.balanceAfter,
      cardLast4: ai.cardLast4 ?? heuristic.cardLast4,
      hints: heuristic.hints,
    );
  }

  TransactionDirection _directionFromName(String value) {
    return TransactionDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => TransactionDirection.unknown,
    );
  }

  TransactionCategory _categoryFromName(String value) {
    return TransactionCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => TransactionCategory.other,
    );
  }

  TransactionRecord _applyStoredFeedback(TransactionRecord record) {
    final store = _feedbackStore;
    if (store == null) {
      return record;
    }
    final category = store.resolve(
      packageName: record.packageName,
      merchantName: record.merchantName,
    );
    if (category == null || category == record.category) {
      return record;
    }
    return TransactionRecord(
      id: record.id,
      receivedAt: record.receivedAt,
      packageName: record.packageName,
      rawTitle: record.rawTitle,
      rawContent: record.rawContent,
      amount: record.amount,
      currency: record.currency,
      direction: record.direction,
      category: category,
      confidence: (record.confidence + 0.08).clamp(0.0, 0.99).toDouble(),
      userCategory: record.userCategory,
      merchantName: record.merchantName,
      balanceAfter: record.balanceAfter,
      cardLast4: record.cardLast4,
      hints: record.hints,
    );
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
