import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_types.dart';

const _prefsMerchantOverrides = 'transaction_feedback_merchants_v1';
const _prefsPackageOverrides = 'transaction_feedback_packages_v1';

class TransactionFeedbackStore extends ChangeNotifier {
  final Map<String, TransactionCategory> _merchantOverrides = {};
  final Map<String, TransactionCategory> _packageOverrides = {};

  Map<String, TransactionCategory> get merchantOverrides =>
      Map.unmodifiable(_merchantOverrides);

  Map<String, TransactionCategory> get packageOverrides =>
      Map.unmodifiable(_packageOverrides);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _merchantOverrides
      ..clear()
      ..addAll(_decodeMap(prefs.getString(_prefsMerchantOverrides)));
    _packageOverrides
      ..clear()
      ..addAll(_decodeMap(prefs.getString(_prefsPackageOverrides)));
    notifyListeners();
  }

  TransactionCategory? resolve({
    required String packageName,
    String? merchantName,
  }) {
    final merchantKey = _normalize(merchantName);
    if (merchantKey != null && _merchantOverrides.containsKey(merchantKey)) {
      return _merchantOverrides[merchantKey];
    }
    final packageKey = _normalize(packageName);
    if (_packageOverrides.containsKey(packageKey)) {
      return _packageOverrides[packageKey];
    }
    return null;
  }

  Future<void> rememberCategory({
    required String packageName,
    String? merchantName,
    required TransactionCategory category,
  }) async {
    final merchantKey = _normalize(merchantName);
    final packageKey = _normalize(packageName);
    final prefs = await SharedPreferences.getInstance();

    if (merchantKey != null && merchantKey.isNotEmpty) {
      _merchantOverrides[merchantKey] = category;
      await prefs.setString(
        _prefsMerchantOverrides,
        jsonEncode(_encodeMap(_merchantOverrides)),
      );
    }
    if (packageKey != null && packageKey.isNotEmpty) {
      _packageOverrides[packageKey] = category;
      await prefs.setString(
        _prefsPackageOverrides,
        jsonEncode(_encodeMap(_packageOverrides)),
      );
    }
    notifyListeners();
  }

  String? _normalize(String? value) {
    final cleaned = value?.trim().toLowerCase();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  Map<String, TransactionCategory> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _mapFromDynamic(decoded);
      }
      if (decoded is Map) {
        return _mapFromDynamic(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  Map<String, TransactionCategory> _mapFromDynamic(
    Map<String, dynamic> map,
  ) {
    final output = <String, TransactionCategory>{};
    for (final entry in map.entries) {
      final category = TransactionCategory.values.firstWhere(
        (value) => value.name == entry.value?.toString(),
        orElse: () => TransactionCategory.other,
      );
      output[entry.key] = category;
    }
    return output;
  }

  Map<String, String> _encodeMap(Map<String, TransactionCategory> map) {
    return map.map((key, value) => MapEntry(key, value.name));
  }
}
