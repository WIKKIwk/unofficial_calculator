import 'package:flutter/foundation.dart';

import 'models/sms_message_entry.dart';

class SmsInboxNotifier extends ChangeNotifier {
  final List<SmsMessageEntry> _items = <SmsMessageEntry>[];

  List<SmsMessageEntry> get items => List.unmodifiable(_items);

  void replaceAll(List<SmsMessageEntry> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }
}
