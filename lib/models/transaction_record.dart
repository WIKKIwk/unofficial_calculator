import 'transaction_types.dart';

class TransactionRecord {
  TransactionRecord({
    required this.id,
    required this.receivedAt,
    required this.packageName,
    required this.rawTitle,
    required this.rawContent,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.category,
    required this.confidence,
    this.merchantName,
    this.balanceAfter,
    this.cardLast4,
    this.hints = const <String>[],
  });

  final String id;
  final DateTime receivedAt;
  final String packageName;
  final String rawTitle;
  final String rawContent;
  final double amount;
  final String currency;
  final TransactionDirection direction;
  final TransactionCategory category;
  final double confidence;
  final String? merchantName;
  final double? balanceAfter;
  final String? cardLast4;
  final List<String> hints;

  bool get isDebit =>
      direction == TransactionDirection.debit ||
      direction == TransactionDirection.fee ||
      direction == TransactionDirection.cashWithdrawal;

  bool get isCredit =>
      direction == TransactionDirection.credit ||
      direction == TransactionDirection.refund;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'receivedAt': receivedAt.toIso8601String(),
      'packageName': packageName,
      'rawTitle': rawTitle,
      'rawContent': rawContent,
      'amount': amount,
      'currency': currency,
      'direction': direction.name,
      'category': category.name,
      'confidence': confidence,
      'merchantName': merchantName,
      'balanceAfter': balanceAfter,
      'cardLast4': cardLast4,
      'hints': hints,
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    final rawHints = map['hints'];
    final hints = rawHints is List
        ? rawHints.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return TransactionRecord(
      id: map['id']?.toString() ?? '',
      receivedAt: DateTime.tryParse(map['receivedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      packageName: map['packageName']?.toString() ?? '',
      rawTitle: map['rawTitle']?.toString() ?? '',
      rawContent: map['rawContent']?.toString() ?? '',
      amount: _asDouble(map['amount']),
      currency: map['currency']?.toString() ?? 'UZS',
      direction: _directionFrom(map['direction']),
      category: _categoryFrom(map['category']),
      confidence: _asDouble(map['confidence']),
      merchantName: map['merchantName']?.toString(),
      balanceAfter: _nullableDouble(map['balanceAfter']),
      cardLast4: map['cardLast4']?.toString(),
      hints: hints,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static TransactionDirection _directionFrom(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return TransactionDirection.unknown;
    }
    return TransactionDirection.values.firstWhere(
      (direction) => direction.name == raw,
      orElse: () => TransactionDirection.unknown,
    );
  }

  static TransactionCategory _categoryFrom(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return TransactionCategory.other;
    }
    return TransactionCategory.values.firstWhere(
      (category) => category.name == raw,
      orElse: () => TransactionCategory.other,
    );
  }
}

