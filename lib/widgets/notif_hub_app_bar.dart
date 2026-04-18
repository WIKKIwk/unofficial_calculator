import 'package:flutter/material.dart';

/// Material 3 top app bar: product name + current section title.
class NotifHubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NotifHubAppBar({super.key, required this.sectionTitle});

  static const String brandTitle = 'Notif Hub';

  final String sectionTitle;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      toolbarHeight: 72,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: scheme.surfaceTint,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            brandTitle,
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sectionTitle,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),
        ],
      ),
    );
  }
}
