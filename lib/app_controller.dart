import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/captured_notification.dart';
import 'models/transaction_record.dart';
import 'models/transaction_types.dart';
import 'models/sms_message_entry.dart';
import 'models/sms_thread_entry.dart';
import 'notification_feed_notifier.dart';
import 'sms_inbox_notifier.dart';
import 'sms_threads_notifier.dart';
import 'services/gemini_transaction_ai_service.dart';
import 'services/local_transaction_notification_service.dart';
import 'services/transaction_feedback_store.dart';
import 'services/transaction_ledger.dart';

const _prefsAllowedPackages = 'allowed_packages';
const _prefsCapturedNotifications = 'captured_notifications_v1';
const _prefsGeminiApiKey = 'gemini_api_key';

String _normPackage(String packageName) => packageName.trim().toLowerCase();

class AppController extends ChangeNotifier {
  static const MethodChannel _smsChannel = MethodChannel('notif_hub/sms');

  AppController() {
    transactionFeedbackStore = TransactionFeedbackStore();
    transactionLedger = TransactionLedger(
      feedbackStore: transactionFeedbackStore,
    );
  }

  bool _listenerGranted = false;
  bool _smsPermissionGranted = false;
  String? _geminiApiKey;
  final Set<String> _allowedPackages = {};
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  Timer? _persistDebounce;

  /// Drives only the permission gate in [MaterialApp] home (not every toast).
  final ValueNotifier<bool> listenerGrantedNotifier = ValueNotifier(false);

  /// Drives only the notifications list UI.
  final NotificationFeedNotifier notificationFeed = NotificationFeedNotifier();
  late final TransactionFeedbackStore transactionFeedbackStore;
  late final TransactionLedger transactionLedger;
  final LocalTransactionNotificationService _localNotificationService =
      LocalTransactionNotificationService.instance;
  final ValueNotifier<bool> geminiConfiguredNotifier = ValueNotifier(false);
  final ValueNotifier<bool> smsPermissionGrantedNotifier = ValueNotifier(false);
  final SmsInboxNotifier smsInbox = SmsInboxNotifier();
  final SmsThreadsNotifier smsThreads = SmsThreadsNotifier();

  bool get listenerGranted => _listenerGranted;
  bool get smsPermissionGranted => _smsPermissionGranted;
  bool get geminiConfigured => _geminiApiKey?.trim().isNotEmpty == true;
  String? get geminiApiKey => _geminiApiKey;
  String get geminiModel => GeminiTransactionAiService.defaultModel;

  Set<String> get allowedPackages => Set.unmodifiable(_allowedPackages);

  List<CapturedNotification> get notifications => notificationFeed.items;
  List<TransactionRecord> get transactions => transactionLedger.items;
  List<SmsMessageEntry> get smsMessages => smsInbox.items;
  List<SmsThreadEntry> get smsThreadItems => smsThreads.items;

  bool isPackageAllowed(String packageName) =>
      _allowedPackages.contains(_normPackage(packageName));

  Future<void> init() async {
    await _loadPrefs();
    await _loadStoredNotifications();
    await _loadGeminiPrefs();
    await transactionFeedbackStore.init();
    await transactionLedger.init();
    await _localNotificationService.init();
    await refreshPermission();
    await refreshSmsPermission();
    if (_smsPermissionGranted) {
      await loadSmsThreads();
    }
    listenerGrantedNotifier.value = _listenerGranted;
  }

  bool get _supportsSmsFeatures =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

    final captured = CapturedNotification.fromEvent(event, DateTime.now());
    notificationFeed.addCaptured(captured);
    unawaited(_handleTransactionEvent(captured));
    _schedulePersistNotifications();
  }

  Future<void> _handleTransactionEvent(CapturedNotification captured) async {
    final record = await transactionLedger.ingestNotification(
      captured,
      geminiApiKey: _geminiApiKey,
      model: geminiModel,
    );
    if (record == null) {
      return;
    }
    if (record.isDebit) {
      unawaited(_localNotificationService.showTransactionPrompt(record));
    }
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

  Future<void> _loadGeminiPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString(_prefsGeminiApiKey);
    geminiConfiguredNotifier.value = geminiConfigured;
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

  Future<void> saveGeminiApiKey(String apiKey) async {
    final cleaned = apiKey.trim();
    final prefs = await SharedPreferences.getInstance();
    if (cleaned.isEmpty) {
      await prefs.remove(_prefsGeminiApiKey);
      _geminiApiKey = null;
    } else {
      await prefs.setString(_prefsGeminiApiKey, cleaned);
      _geminiApiKey = cleaned;
    }
    geminiConfiguredNotifier.value = geminiConfigured;
    notifyListeners();
  }

  Future<void> clearGeminiApiKey() => saveGeminiApiKey('');

  Future<void> reviewTransaction(
    String transactionId,
    TransactionCategory category,
  ) async {
    final before = transactionLedger.findById(transactionId);
    if (before == null) {
      return;
    }
    await transactionLedger.updateCategory(transactionId, category);
    final after = transactionLedger.findById(transactionId);
    if (after == null) {
      return;
    }
    await transactionFeedbackStore.rememberCategory(
      packageName: after.packageName,
      merchantName: after.merchantName,
      category: category,
    );
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

  Future<void> refreshSmsPermission() async {
    if (!_supportsSmsFeatures) {
      _smsPermissionGranted = false;
      smsPermissionGrantedNotifier.value = false;
      notifyListeners();
      return;
    }
    final status = await Permission.sms.status;
    final granted = status.isGranted;
    if (granted != _smsPermissionGranted) {
      _smsPermissionGranted = granted;
      smsPermissionGrantedNotifier.value = granted;
      notifyListeners();
    } else {
      smsPermissionGrantedNotifier.value = granted;
    }
  }

  Future<void> requestSmsPermission() async {
    if (!_supportsSmsFeatures) {
      return;
    }
    await Permission.sms.request();
    await refreshSmsPermission();
    if (_smsPermissionGranted) {
      await loadSmsThreads();
    }
  }

  Future<void> loadSmsInbox({int limit = 500}) async {
    if (!_supportsSmsFeatures || !_smsPermissionGranted) {
      return;
    }
    final raw = await _smsChannel.invokeMethod<List<dynamic>>(
      'fetchSmsInbox',
      <String, dynamic>{'limit': limit},
    );
    if (raw == null) {
      smsInbox.replaceAll(const <SmsMessageEntry>[]);
      return;
    }
    final parsed = <SmsMessageEntry>[];
    for (final item in raw) {
      if (item is Map) {
        parsed.add(SmsMessageEntry.fromMap(item.cast<String, dynamic>()));
      }
    }
    smsInbox.replaceAll(parsed);
  }

  Future<void> loadSmsThreads({int limit = 120}) async {
    if (!_supportsSmsFeatures || !_smsPermissionGranted) {
      return;
    }
    final raw = await _smsChannel.invokeMethod<List<dynamic>>(
      'fetchSmsThreads',
      <String, dynamic>{'limit': limit},
    );
    if (raw == null) {
      smsThreads.replaceAll(const <SmsThreadEntry>[]);
      return;
    }
    final parsed = <SmsThreadEntry>[];
    for (final item in raw) {
      if (item is Map) {
        parsed.add(SmsThreadEntry.fromMap(item.cast<String, dynamic>()));
      }
    }
    smsThreads.replaceAll(parsed);
  }

  Future<void> loadSmsThreadMessages(int threadId, {int limit = 500}) async {
    if (!_supportsSmsFeatures || !_smsPermissionGranted) {
      return;
    }
    List<dynamic>? raw;
    try {
      raw = await _smsChannel.invokeMethod<List<dynamic>>(
        'fetchSmsThreadMessages',
        <String, dynamic>{'threadId': threadId, 'limit': limit},
      );
    } on PlatformException {
      smsInbox.replaceAll(const <SmsMessageEntry>[]);
      return;
    }
    if (raw == null) {
      smsInbox.replaceAll(const <SmsMessageEntry>[]);
      return;
    }
    final parsed = <SmsMessageEntry>[];
    for (final item in raw) {
      if (item is Map) {
        parsed.add(SmsMessageEntry.fromMap(item.cast<String, dynamic>()));
      }
    }
    smsInbox.replaceAll(parsed);
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
    geminiConfiguredNotifier.dispose();
    smsPermissionGrantedNotifier.dispose();
    notificationFeed.dispose();
    transactionFeedbackStore.dispose();
    transactionLedger.dispose();
    smsInbox.dispose();
    smsThreads.dispose();
    super.dispose();
  }
}
