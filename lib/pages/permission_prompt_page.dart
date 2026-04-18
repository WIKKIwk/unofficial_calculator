import 'package:flutter/material.dart';

import '../app_controller.dart';

class PermissionPromptPage extends StatelessWidget {
  const PermissionPromptPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.notifications_active_rounded,
                size: 72,
                color: scheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Bildirishnoma kirish ruxsati',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ilova boshqa ilovalardan kelgan bildirishnomalarni '
                'yig‘ish uchun Android tizimida “Bildirishnoma kirish” '
                'ruxsatini yoqishingiz kerak. Bu ruxsatsiz dastur ishlamaydi.',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => controller.openListenerSettings(),
                icon: const Icon(Icons.settings_suggest_outlined),
                label: const Text('Ruxsat berish (tizim sozlamalari)'),
              ),
              const SizedBox(height: 12),
              Text(
                'Tizim sahifasida ilovangizni topib, bildirishnoma kirishini yoqing.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
