import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../widgets/notif_hub_app_bar.dart';
import 'dashboard_page.dart';
import 'notifications_page.dart';
import 'settings_page.dart';
import 'sms_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  static const _titles = [
    'Dashboard',
    'Bildirishnomalar',
    'SMS',
    'Sozlamalar',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NotifHubAppBar(
        sectionTitle: _titles[_index],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(controller: widget.controller),
          NotificationsPage(controller: widget.controller),
          SmsPage(controller: widget.controller),
          SettingsPage(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Bildirishnomalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms),
            label: 'SMS',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Sozlamalar',
          ),
        ],
      ),
    );
  }
}
