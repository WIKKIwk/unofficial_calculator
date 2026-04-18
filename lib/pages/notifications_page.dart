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

        return ListTileTheme(
          data: ListTileThemeData(
            tileColor: Colors.transparent,
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            minLeadingWidth: 40,
            titleTextStyle: textTheme.titleMedium,
            subtitleTextStyle: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            itemBuilder: (context, index) {
              final CapturedNotification n = items[index];
              return ListTile(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (n.content != null && n.content!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          n.content!.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 2),
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
          ),
        );
      },
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.iconBytes, required this.package});

  final Uint8List? iconBytes;
  final String package;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = iconBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return SizedBox(
        width: _size,
        height: _size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _PlaceholderIcon(scheme: scheme),
          ),
        ),
      );
    }
    return _PlaceholderIcon(scheme: scheme);
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _Leading._size,
      height: _Leading._size,
      child: Icon(
        Icons.notifications_outlined,
        size: 24,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
