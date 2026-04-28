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

  void hydrate(List<CapturedNotification> initialItems) {
    _items
      ..clear()
      ..addAll(initialItems.take(_maxItems));
    notifyListeners();
  }

  void addCaptured(CapturedNotification notification) {
    _items.insert(0, notification);
    while (_items.length > _maxItems) {
      _items.removeLast();
    }
    _scheduleNotify();
  }

  void addFromEvent(ServiceNotificationEvent event, DateTime receivedAt) {
    addCaptured(CapturedNotification.fromEvent(event, receivedAt));
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
