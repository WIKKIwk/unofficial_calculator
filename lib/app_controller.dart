import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/captured_notification.dart';
import 'notification_feed_notifier.dart';

const _prefsAllowedPackages = 'allowed_packages';

class AppController extends ChangeNotifier {
  AppController();

  bool _listenerGranted = false;
  final Set<String> _allowedPackages = {};
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  /// Drives only the permission gate in [MaterialApp] home (not every toast).
  final ValueNotifier<bool> listenerGrantedNotifier = ValueNotifier(false);

  /// Drives only the notifications list UI.
  final NotificationFeedNotifier notificationFeed = NotificationFeedNotifier();

  bool get listenerGranted => _listenerGranted;

  Set<String> get allowedPackages => Set.unmodifiable(_allowedPackages);

  List<CapturedNotification> get notifications => notificationFeed.items;

  bool isPackageAllowed(String packageName) =>
      _allowedPackages.contains(packageName);

  Future<void> init() async {
    await _loadPrefs();
    await refreshPermission();
    listenerGrantedNotifier.value = _listenerGranted;
  }

  Future<void> refreshPermission() async {
    final granted = await NotificationListenerService.isPermissionGranted();
    if (granted != _listenerGranted) {
      _listenerGranted = granted;
      listenerGrantedNotifier.value = granted;
      if (granted) {
        await _ensureSubscribed();
      } else {
        await _subscription?.cancel();
        _subscription = null;
      }
      notifyListeners();
    } else if (granted && _subscription == null) {
      await _ensureSubscribed();
    }
  }

  Future<void> _ensureSubscribed() async {
    if (_subscription != null) return;
    _subscription = NotificationListenerService.notificationsStream.listen(
      _onEvent,
    );
  }

  void _onEvent(ServiceNotificationEvent event) {
    if (event.hasRemoved == true) return;
    final package = event.packageName;
    if (package == null || package.isEmpty) return;
    if (!_allowedPackages.contains(package)) return;

    notificationFeed.addFromEvent(event, DateTime.now());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsAllowedPackages);
    if (stored != null) {
      _allowedPackages
        ..clear()
        ..addAll(stored);
    }
    notifyListeners();
  }

  Future<void> setPackageAllowed(String packageName, bool allowed) async {
    if (allowed) {
      _allowedPackages.add(packageName);
    } else {
      _allowedPackages.remove(packageName);
    }
    await _savePrefs();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsAllowedPackages,
      _allowedPackages.toList()..sort(),
    );
  }

  Future<void> openListenerSettings() async {
    await NotificationListenerService.requestPermission();
    await refreshPermission();
  }

  @override
  void dispose() {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    listenerGrantedNotifier.dispose();
    notificationFeed.dispose();
    super.dispose();
  }
}
