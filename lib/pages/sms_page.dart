import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/sms_message_entry.dart';

class SmsPage extends StatelessWidget {
  const SmsPage({super.key, required this.controller});

  final AppController controller;

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: controller.smsPermissionGrantedNotifier,
      builder: (context, _) {
        if (!controller.smsPermissionGranted) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SMS o‘qish uchun ruxsat kerak.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: controller.requestSmsPermission,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('SMS ruxsatini berish'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListenableBuilder(
          listenable: controller.smsInbox,
          builder: (context, _) {
            final items = controller.smsMessages;
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'SMS topilmadi',
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: controller.loadSmsInbox,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final SmsMessageEntry m = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(Icons.sms_outlined, color: scheme.secondary),
                    title: Text(
                      m.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      m.body.trim().isEmpty
                          ? 'Bo‘sh xabar'
                          : '${m.body}\n${_formatTime(m.receivedAt)}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
