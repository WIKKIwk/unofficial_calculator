import 'dart:convert';
import 'dart:io';

class GeminiTransactionAnalysis {
  GeminiTransactionAnalysis({
    required this.isTransaction,
    required this.confidence,
    required this.direction,
    required this.category,
    required this.currency,
    this.amount,
    this.merchantName,
    this.balanceAfter,
    this.cardLast4,
    this.summary,
  });

  final bool isTransaction;
  final double confidence;
  final String direction;
  final String category;
  final String currency;
  final double? amount;
  final String? merchantName;
  final double? balanceAfter;
  final String? cardLast4;
  final String? summary;

  factory GeminiTransactionAnalysis.fromJson(Map<String, dynamic> json) {
    return GeminiTransactionAnalysis(
      isTransaction: json['isTransaction'] == true,
      confidence: _asDouble(json['confidence']),
      direction: json['direction']?.toString() ?? 'unknown',
      category: json['category']?.toString() ?? 'other',
      currency: json['currency']?.toString() ?? 'UZS',
      amount: _asNullableDouble(json['amount']),
      merchantName: json['merchantName']?.toString(),
      balanceAfter: _asNullableDouble(json['balanceAfter']),
      cardLast4: json['cardLast4']?.toString(),
      summary: json['summary']?.toString(),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class GeminiTransactionAiService {
  const GeminiTransactionAiService();

  static const String defaultModel = 'gemini-2.5-flash';

  Future<GeminiTransactionAnalysis?> analyze({
    required String apiKey,
    required String title,
    required String content,
    required String packageName,
    String model = defaultModel,
  }) async {
    final prompt = _buildPrompt(
      title: title,
      content: content,
      packageName: packageName,
    );
    final response = await _postJson(
      apiKey: apiKey,
      model: model,
      body: <String, dynamic>{
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          'topP': 0.1,
          'responseMimeType': 'application/json',
          'responseJsonSchema': _schema,
        },
      },
    );
    if (response == null) {
      return null;
    }

    try {
      final candidates = response['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        return null;
      }
      final first = candidates.first;
      if (first is! Map) {
        return null;
      }
      final content = first['content'];
      if (content is! Map) {
        return null;
      }
      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        return null;
      }
      final part = parts.first;
      if (part is! Map) {
        return null;
      }
      final text = part['text']?.toString();
      if (text == null || text.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return GeminiTransactionAnalysis.fromJson(decoded);
      }
      if (decoded is Map) {
        return GeminiTransactionAnalysis.fromJson(
          decoded.cast<String, dynamic>(),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _postJson({
    required String apiKey,
    required String model,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('x-goog-api-key', apiKey);
      request.write(jsonEncode(body));

      final response = await request.close();
      final responseText = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(responseText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
    return null;
  }

  String _buildPrompt({
    required String title,
    required String content,
    required String packageName,
  }) {
    return [
      'You are extracting a banking transaction from an Android notification.',
      'Return ONLY the JSON object matching the schema.',
      'If the notification is not a financial transaction, set isTransaction to false and confidence low.',
      'Prefer debit/credit/transfer/refund/fee/cashWithdrawal categories.',
      'Input fields:',
      'packageName: $packageName',
      'title: $title',
      'content: $content',
      'Guidance:',
      '- Extract the amount if present.',
      '- Detect merchant or recipient name if possible.',
      '- Use UZS unless the text strongly indicates another currency.',
      '- cardLast4 should be the last 4 digits if present, otherwise null.',
    ].join('\n');
  }

  static const Map<String, dynamic> _schema = <String, dynamic>{
    'type': 'object',
    'properties': {
      'isTransaction': {
        'type': 'boolean',
        'description': 'Whether this notification is a financial transaction.',
      },
      'confidence': {
        'type': 'number',
        'description': 'Confidence from 0 to 1.',
        'minimum': 0,
        'maximum': 1,
      },
      'direction': {
        'type': 'string',
        'description': 'Direction of money flow.',
        'enum': [
          'debit',
          'credit',
          'transfer',
          'fee',
          'refund',
          'cashWithdrawal',
          'unknown',
        ],
      },
      'category': {
        'type': 'string',
        'description': 'Spending category.',
        'enum': [
          'groceries',
          'food',
          'transport',
          'shopping',
          'utilities',
          'mobileTopUp',
          'cashWithdrawal',
          'transfer',
          'fees',
          'income',
          'entertainment',
          'health',
          'education',
          'other',
        ],
      },
      'currency': {
        'type': 'string',
        'description': 'Currency code.',
        'enum': ['UZS', 'USD', 'EUR', 'RUB'],
      },
      'amount': {
        'type': ['number', 'null'],
        'description': 'Transaction amount if present.',
      },
      'merchantName': {
        'type': ['string', 'null'],
        'description': 'Merchant, recipient or counterparty if present.',
      },
      'balanceAfter': {
        'type': ['number', 'null'],
        'description': 'Remaining balance after transaction if present.',
      },
      'cardLast4': {
        'type': ['string', 'null'],
        'description': 'Last four digits of the card if present.',
      },
      'summary': {
        'type': ['string', 'null'],
        'description': 'Short human-readable explanation of the transaction.',
      },
    },
    'required': [
      'isTransaction',
      'confidence',
      'direction',
      'category',
      'currency',
      'amount',
      'merchantName',
      'balanceAfter',
      'cardLast4',
      'summary',
    ],
    'additionalProperties': false,
  };
}

