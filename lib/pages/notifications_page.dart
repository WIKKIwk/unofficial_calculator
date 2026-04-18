import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/captured_notification.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.controller});

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
      listenable: controller,
      builder: (context, _) {
        if (!controller.listenerGranted) {
          return const SizedBox.shrink();
        }

        if (controller.allowedPackages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sozlamalar bo‘limida tinglamoqchi bo‘lgan ilovalarni yoqing.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final items = controller.notifications;
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Hali bildirishnoma yo‘q',
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          itemBuilder: (context, index) {
            final CapturedNotification n = items[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: _Leading(iconBytes: n.appIcon, package: n.packageName),
              title: Text(
                n.title?.trim().isNotEmpty == true
                    ? n.title!.trim()
                    : n.packageName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.content != null && n.content!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        n.content!.trim(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${n.packageName} · ${_formatTime(n.receivedAt)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.iconBytes, required this.package});

  final Uint8List? iconBytes;
  final String package;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = iconBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: ClipOval(
          child: Image.memory(
            bytes,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _Initial(scheme: scheme, package: package),
          ),
        ),
      );
    }
    return _Initial(scheme: scheme, package: package);
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.scheme, required this.package});

  final ColorScheme scheme;
  final String package;

  @override
  Widget build(BuildContext context) {
    final letter = package.isNotEmpty ? package[0].toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(letter),
    );
  }
}
