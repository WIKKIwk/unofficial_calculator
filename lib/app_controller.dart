import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/captured_notification.dart';
import 'notification_feed_notifier.dart';

const _prefsAllowedPackages = 'allowed_packages';
const _prefsCapturedNotifications = 'captured_notifications_v1';

String _normPackage(String packageName) => packageName.trim().toLowerCase();

class AppController extends ChangeNotifier {
  AppController();

  bool _listenerGranted = false;
  final Set<String> _allowedPackages = {};
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  Timer? _persistDebounce;

  /// Drives only the permission gate in [MaterialApp] home (not every toast).
  final ValueNotifier<bool> listenerGrantedNotifier = ValueNotifier(false);

  /// Drives only the notifications list UI.
  final NotificationFeedNotifier notificationFeed = NotificationFeedNotifier();

  bool get listenerGranted => _listenerGranted;

  Set<String> get allowedPackages => Set.unmodifiable(_allowedPackages);

  List<CapturedNotification> get notifications => notificationFeed.items;

  bool isPackageAllowed(String packageName) =>
      _allowedPackages.contains(_normPackage(packageName));

  Future<void> init() async {
    await _loadPrefs();
    await _loadStoredNotifications();
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
      onError: (Object error, StackTrace stackTrace) {
        // Plugin stream can occasionally restart; recover automatically.
        _subscription = null;
        if (_listenerGranted) {
          unawaited(_ensureSubscribed());
        }
      },
      onDone: () {
        _subscription = null;
        if (_listenerGranted) {
          unawaited(_ensureSubscribed());
        }
      },
    );
  }

  void _onEvent(ServiceNotificationEvent event) {
    if (event.hasRemoved == true) return;
    final package = event.packageName;
    if (package == null || package.trim().isEmpty) return;
    final normalizedPackage = _normPackage(package);
    if (!_allowedPackages.contains(normalizedPackage)) return;

    notificationFeed.addFromEvent(event, DateTime.now());
    _schedulePersistNotifications();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsAllowedPackages);
    if (stored != null) {
      _allowedPackages
        ..clear()
        ..addAll(stored.map(_normPackage));
    }
    notifyListeners();
  }

  Future<void> _loadStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsCapturedNotifications);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final parsed = <CapturedNotification>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          parsed.add(CapturedNotification.fromMap(decoded));
        } else if (decoded is Map) {
          parsed.add(
            CapturedNotification.fromMap(decoded.cast<String, dynamic>()),
          );
        }
      } catch (_) {
        // Skip malformed records to avoid breaking app startup.
      }
    }
    if (parsed.isNotEmpty) {
      notificationFeed.hydrate(parsed);
    }
  }

  Future<void> setPackageAllowed(String packageName, bool allowed) async {
    final normalizedPackage = _normPackage(packageName);
    if (allowed) {
      _allowedPackages.add(normalizedPackage);
    } else {
      _allowedPackages.remove(normalizedPackage);
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

  void _schedulePersistNotifications() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_persistNotificationsNow());
    });
  }

  Future<void> _persistNotificationsNow() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = notificationFeed.items
        .map((n) => jsonEncode(n.toMap()))
        .toList();
    await prefs.setStringList(_prefsCapturedNotifications, encoded);
  }

  Future<void> openListenerSettings() async {
    await NotificationListenerService.requestPermission();
    await refreshPermission();
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    unawaited(_persistNotificationsNow());
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
