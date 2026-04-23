import 'dart:typed_data';

import 'package:notification_listener_service/notification_event.dart';

class CapturedNotification {
  CapturedNotification({
    required this.receivedAt,
    required this.packageName,
    this.title,
    this.content,
    this.appIcon,
  });

  final DateTime receivedAt;
  final String packageName;
  final String? title;
  final String? content;
  final Uint8List? appIcon;

  factory CapturedNotification.fromEvent(
    ServiceNotificationEvent e,
    DateTime receivedAt,
  ) {
    return CapturedNotification(
      receivedAt: receivedAt,
      packageName: e.packageName ?? '',
      title: e.title,
      content: e.content,
      appIcon: e.appIcon,
    );
  }

  factory CapturedNotification.fromMap(Map<String, dynamic> map) {
    return CapturedNotification(
      receivedAt: DateTime.tryParse(map['receivedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String?,
      content: map['content'] as String?,
      // Icon bytes are intentionally not persisted to keep storage small.
      appIcon: null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'receivedAt': receivedAt.toIso8601String(),
      'packageName': packageName,
      'title': title,
      'content': content,
    };
  }
}
