import '../models/transaction_types.dart';

class TransactionClassification {
  TransactionClassification({
    required this.direction,
    required this.category,
    required this.merchantName,
    required this.currency,
    required this.amount,
    required this.balanceAfter,
    required this.cardLast4,
    required this.confidence,
    required this.hints,
  });

  final TransactionDirection direction;
  final TransactionCategory category;
  final String? merchantName;
  final String currency;
  final double? amount;
  final double? balanceAfter;
  final String? cardLast4;
  final double confidence;
  final List<String> hints;
}

class TransactionClassifier {
  const TransactionClassifier();

  TransactionClassification classify({
    required String title,
    required String content,
    required String packageName,
  }) {
    final rawText = _normalize('$title $content');
    final direction = _detectDirection(rawText);
    final category = _detectCategory(rawText, direction);
    final amount = _extractAmount(rawText);
    final balanceAfter = _extractBalance(rawText);
    final currency = _detectCurrency(rawText);
    final cardLast4 = _extractCardLast4(rawText);
    final merchantName = _extractMerchantName(rawText, category);
    final hints = _collectHints(rawText, category, direction, merchantName, amount, balanceAfter);
    final confidence = _score(
      packageName: packageName,
      amount: amount,
      direction: direction,
      category: category,
      merchantName: merchantName,
      hints: hints,
    );

    return TransactionClassification(
      direction: direction,
      category: category,
      merchantName: merchantName,
      currency: currency,
      amount: amount,
      balanceAfter: balanceAfter,
      cardLast4: cardLast4,
      confidence: confidence,
      hints: hints,
    );
  }

  bool looksLikeTransaction({
    required String title,
    required String content,
    required String packageName,
  }) {
    final rawText = _normalize('$title $content');
    if (_extractAmount(rawText) != null) {
      return true;
    }
    return _detectDirection(rawText) != TransactionDirection.unknown &&
        _isLikelyBankOrSmsPackage(packageName);
  }

  bool _isLikelyBankOrSmsPackage(String packageName) {
    final pkg = packageName.toLowerCase();
    return pkg.contains('bank') ||
        pkg.contains('payme') ||
        pkg.contains('click') ||
        pkg.contains('wallet') ||
        pkg.contains('card') ||
        pkg.contains('sms') ||
        pkg.contains('messaging');
  }

  TransactionDirection _detectDirection(String text) {
    if (_containsAny(text, _cashWithdrawalHints)) {
      return TransactionDirection.cashWithdrawal;
    }
    if (_containsAny(text, _feeHints)) {
      return TransactionDirection.fee;
    }
    if (_containsAny(text, _refundHints)) {
      return TransactionDirection.refund;
    }
    if (_containsAny(text, _transferHints)) {
      return TransactionDirection.transfer;
    }
    if (_containsAny(text, _creditHints)) {
      return TransactionDirection.credit;
    }
    if (_containsAny(text, _debitHints)) {
      return TransactionDirection.debit;
    }
    return TransactionDirection.unknown;
  }

  TransactionCategory _detectCategory(
    String text,
    TransactionDirection direction,
  ) {
    if (direction == TransactionDirection.cashWithdrawal) {
      return TransactionCategory.cashWithdrawal;
    }
    if (direction == TransactionDirection.fee) {
      return TransactionCategory.fees;
    }
    if (direction == TransactionDirection.transfer) {
      return TransactionCategory.transfer;
    }
    if (direction == TransactionDirection.credit &&
        _containsAny(text, _incomeHints)) {
      return TransactionCategory.income;
    }

    final categoryScores = <TransactionCategory, int>{
      TransactionCategory.groceries: _scoreHints(text, _groceryHints),
      TransactionCategory.food: _scoreHints(text, _foodHints),
      TransactionCategory.transport: _scoreHints(text, _transportHints),
      TransactionCategory.shopping: _scoreHints(text, _shoppingHints),
      TransactionCategory.utilities: _scoreHints(text, _utilityHints),
      TransactionCategory.mobileTopUp: _scoreHints(text, _mobileHints),
      TransactionCategory.entertainment: _scoreHints(text, _entertainmentHints),
      TransactionCategory.health: _scoreHints(text, _healthHints),
      TransactionCategory.education: _scoreHints(text, _educationHints),
      TransactionCategory.income: _scoreHints(text, _incomeHints),
    };

    final best = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (best.isNotEmpty && best.first.value > 0) {
      return best.first.key;
    }
    return TransactionCategory.other;
  }

  String? _extractMerchantName(String text, TransactionCategory category) {
    for (final hint in [
      ..._groceryMerchantHints,
      ..._foodMerchantHints,
      ..._transportMerchantHints,
      ..._shoppingMerchantHints,
      ..._mobileMerchantHints,
    ]) {
      if (text.contains(hint)) {
        return _titleCase(hint);
      }
    }

    final pattern = RegExp(
      r"""([a-z0-9'"&.-]+(?:\s+[a-z0-9'"&.-]+){0,3})\s+(?:so'?m|som|uzs|sum|usd|eur|rub|karta|card|payment|yechildi|debited|withdrawn|spent)""",
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final candidate = match.group(1)?.trim();
      if (candidate != null && candidate.length >= 3) {
        return _titleCase(candidate);
      }
    }

    if (category != TransactionCategory.other) {
      return category.label;
    }
    return null;
  }

  List<String> _collectHints(
    String text,
    TransactionCategory category,
    TransactionDirection direction,
    String? merchantName,
    double? amount,
    double? balanceAfter,
  ) {
    final hints = <String>[];
    if (direction != TransactionDirection.unknown) {
      hints.add(direction.name);
    }
    if (category != TransactionCategory.other) {
      hints.add(category.name);
    }
    if (merchantName != null && merchantName.isNotEmpty) {
      hints.add('merchant');
    }
    if (amount != null) {
      hints.add('amount');
    }
    if (balanceAfter != null) {
      hints.add('balance');
    }
    if (_containsAny(text, _cardHints)) {
      hints.add('card');
    }
    return hints;
  }

  double _score({
    required String packageName,
    required double? amount,
    required TransactionDirection direction,
    required TransactionCategory category,
    required String? merchantName,
    required List<String> hints,
  }) {
    var score = 0.15;
    if (_isLikelyBankOrSmsPackage(packageName)) {
      score += 0.2;
    }
    if (amount != null) {
      score += 0.25;
    }
    if (direction != TransactionDirection.unknown) {
      score += 0.2;
    }
    if (category != TransactionCategory.other) {
      score += 0.15;
    }
    if (merchantName != null && merchantName.isNotEmpty) {
      score += 0.1;
    }
    score += (hints.length * 0.02).clamp(0, 0.1);
    return score.clamp(0.0, 0.99).toDouble();
  }

  double? _extractAmount(String text) {
    final candidates = <_AmountCandidate>[];

    for (final line in text.split(RegExp(r'[\n\r]+'))) {
      final amount = _amountFromLine(line);
      if (amount != null) {
        candidates.add(amount);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.score.compareTo(a.score));
      return candidates.first.value;
    }

    final fallback = RegExp(r'(\d[\d\s.,]{1,18})').allMatches(text);
    double? bestValue;
    for (final match in fallback) {
      final value = _parseAmount(match.group(1));
      if (value == null) {
        continue;
      }
      if (bestValue == null || value > bestValue) {
        bestValue = value;
      }
    }
    return bestValue;
  }

  _AmountCandidate? _amountFromLine(String line) {
    final amountPattern = RegExp(
      r"""(\d[\d\s.,]{1,18})\s*(so'?m|som|uzs|sum|usd|eur|rub|kzt|usd\.?|eur\.?|rub\.?|₽|\$|€)?""",
    );
    final matches = amountPattern.allMatches(line).toList();
    if (matches.isEmpty) {
      return null;
    }

    final scored = <_AmountCandidate>[];
    for (final match in matches) {
      final value = _parseAmount(match.group(1));
      if (value == null) {
        continue;
      }
      var score = 1.0;
      final lower = line.toLowerCase();
      for (final keyword in _debitHints) {
        if (lower.contains(keyword)) {
          score += 0.75;
          break;
        }
      }
      for (final keyword in _creditHints) {
        if (lower.contains(keyword)) {
          score += 0.55;
          break;
        }
      }
      for (final keyword in _balanceHints) {
        if (lower.contains(keyword)) {
          score -= 0.45;
          break;
        }
      }
      scored.add(_AmountCandidate(value: value, score: score));
    }

    if (scored.isEmpty) {
      return null;
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.first;
  }

  double? _extractBalance(String text) {
    final balancePattern = RegExp(
      r'(?:balance|ostatok|qoldiq|balans|hisobda|remaining)\D{0,20}(\d[\d\s.,]{1,18})',
    );
    final match = balancePattern.firstMatch(text);
    if (match == null) {
      return null;
    }
    return _parseAmount(match.group(1));
  }

  String _detectCurrency(String text) {
    if (_containsAny(text, _usdHints)) {
      return 'USD';
    }
    if (_containsAny(text, _eurHints)) {
      return 'EUR';
    }
    if (_containsAny(text, _rubHints)) {
      return 'RUB';
    }
    return 'UZS';
  }

  String? _extractCardLast4(String text) {
    final match = RegExp(r'(?:\*{2,}|\u2022{2,})?(\d{4})\b').firstMatch(text);
    return match?.group(1);
  }

  double? _parseAmount(String? raw) {
    if (raw == null) {
      return null;
    }
    var value = raw.replaceAll(RegExp(r'[^0-9,.\s]'), '');
    value = value.replaceAll(' ', '');
    if (value.isEmpty) {
      return null;
    }
    if (value.contains(',') && value.contains('.')) {
      final lastComma = value.lastIndexOf(',');
      final lastDot = value.lastIndexOf('.');
      final decimalSeparator = lastComma > lastDot ? ',' : '.';
      if (decimalSeparator == ',') {
        value = value.replaceAll('.', '');
        value = value.replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (value.contains(',')) {
      final parts = value.split(',');
      if (parts.length == 2 && parts.last.length == 2) {
        value = value.replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    }
    return double.tryParse(value);
  }

  String _normalize(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  int _scoreHints(String text, List<String> keywords) {
    var score = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        score++;
      }
    }
    return score;
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length == 1) {
            return part.toUpperCase();
          }
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  static const _debitHints = <String>[
    'yechildi',
    'debited',
    'withdrawn',
    'spent',
    'payment',
    "to'lov",
    'tolov',
    'purchase',
    'xarid',
    'sotib olindi',
    'komissiya',
    'fee',
    'charge',
  ];

  static const _creditHints = <String>[
    'keldi',
    'tushdi',
    'credited',
    'received',
    'refund',
    'qaytdi',
    'returned',
    'deposited',
    'top up',
  ];

  static const _transferHints = <String>[
    'transfer',
    'otkazma',
    "o'tkazma",
    'перевод',
  ];

  static const _feeHints = <String>[
    'fee',
    'commission',
    'komissiya',
    'service charge',
  ];

  static const _refundHints = <String>[
    'refund',
    'qaytardi',
    'returned',
    'reversal',
  ];

  static const _cashWithdrawalHints = <String>[
    'cash withdrawal',
    'atm',
    'bankomat',
    'naqd',
    'cash out',
  ];

  static const _balanceHints = <String>[
    'balance',
    'ostatok',
    'qoldiq',
    'balans',
    'hisobda',
    'remaining',
  ];

  static const _usdHints = <String>[
    'usd',
    '\$',
    'dollar',
  ];

  static const _eurHints = <String>[
    'eur',
    '€',
  ];

  static const _rubHints = <String>[
    'rub',
    '₽',
    'ruble',
  ];

  static const _incomeHints = <String>[
    'salary',
    'maosh',
    'ish haqi',
    'wage',
    'stipend',
    'grant',
    'bonus',
  ];

  static const _groceryHints = <String>[
    'supermarket',
    'grocery',
    'market',
    'korzinka',
    'makro',
    'baraka',
    'fresko',
  ];

  static const _foodHints = <String>[
    'restaurant',
    'cafe',
    'coffee',
    'kfc',
    'evos',
    'oqtepa',
    'bellissimo',
    'chopar',
    'burger',
    'pizza',
    'food',
    'dinner',
    'lunch',
    'breakfast',
  ];

  static const _transportHints = <String>[
    'taxi',
    'yandex',
    'indrive',
    'metro',
    'bus',
    'transport',
    'fuel',
    'petrol',
    'gas station',
    'shell',
    'benzin',
  ];

  static const _shoppingHints = <String>[
    'shop',
    'store',
    'mall',
    'marketplace',
    'wildberries',
    'uzum',
    'temu',
    'amazon',
    'aliexpress',
    'electronics',
  ];

  static const _utilityHints = <String>[
    'internet',
    'mobile',
    'electric',
    'water',
    'gas',
    'kommunal',
    'utilities',
    'service payment',
  ];

  static const _mobileHints = <String>[
    'top up',
    'recharge',
    'balance top',
    'beeline',
    'mobiuz',
    'ucell',
    'humans',
    'uzmobile',
  ];

  static const _entertainmentHints = <String>[
    'cinema',
    'movie',
    'steam',
    'netflix',
    'spotify',
    'game',
    'concert',
  ];

  static const _healthHints = <String>[
    'pharmacy',
    'apteka',
    'clinic',
    'hospital',
    'doctor',
  ];

  static const _educationHints = <String>[
    'school',
    'university',
    'course',
    'training',
    'lesson',
    'education',
  ];

  static const _groceryMerchantHints = <String>[
    'korzinka',
    'makro',
    'baraka',
    'fresko',
  ];

  static const _foodMerchantHints = <String>[
    'kfc',
    'evos',
    'oqtepa',
    'bellissimo',
    'chopar',
    'burger',
    'pizza',
    'restaurant',
    'cafe',
  ];

  static const _transportMerchantHints = <String>[
    'yandex',
    'indrive',
    'taxi',
    'shell',
    'petrol',
  ];

  static const _shoppingMerchantHints = <String>[
    'uzum',
    'wildberries',
    'temu',
    'aliexpress',
    'amazon',
  ];

  static const _mobileMerchantHints = <String>[
    'beeline',
    'mobiuz',
    'ucell',
    'humans',
    'uzmobile',
  ];

  static const _cardHints = <String>[
    'card',
    'karta',
    '****',
    '•',
  ];
}

class _AmountCandidate {
  _AmountCandidate({required this.value, required this.score});

  final double value;
  final double score;
}
