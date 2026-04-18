import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';

import 'models/captured_notification.dart';

/// Holds captured notifications and notifies listeners in a single microtask
/// per event burst (avoids rebuilding the whole app on every system tick).
class NotificationFeedNotifier extends ChangeNotifier {
  final List<CapturedNotification> _items = <CapturedNotification>[];

  static const int _maxItems = 600;

  bool _notifyScheduled = false;

  List<CapturedNotification> get items => List.unmodifiable(_items);

  void addFromEvent(ServiceNotificationEvent event, DateTime receivedAt) {
    _items.insert(0, CapturedNotification.fromEvent(event, receivedAt));
    while (_items.length > _maxItems) {
      _items.removeLast();
    }
    _scheduleNotify();
  }

  void _scheduleNotify() {
    if (_notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }
}
