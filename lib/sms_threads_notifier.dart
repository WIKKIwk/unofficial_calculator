import 'package:flutter/foundation.dart';

import 'models/sms_thread_entry.dart';

class SmsThreadsNotifier extends ChangeNotifier {
  final List<SmsThreadEntry> _items = <SmsThreadEntry>[];

  List<SmsThreadEntry> get items => List.unmodifiable(_items);

  void replaceAll(List<SmsThreadEntry> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }
}
