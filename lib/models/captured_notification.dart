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
}
