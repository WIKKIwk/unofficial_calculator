import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

import 'app_controller.dart';
import 'pages/app_shell.dart';
import 'pages/permission_prompt_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const previewEnabled = bool.fromEnvironment(
    'DEVICE_PREVIEW',
    defaultValue: false,
  );
  runApp(
    DevicePreview(
      enabled: previewEnabled,
      builder: (context) => const NotifRoot(),
    ),
  );
}

class NotifRoot extends StatefulWidget {
  const NotifRoot({super.key});

  @override
  State<NotifRoot> createState() => _NotifRootState();
}

class _NotifRootState extends State<NotifRoot> with WidgetsBindingObserver {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    WidgetsBinding.instance.addObserver(this);
    _controller.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notif Hub',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006A6A),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FD8D8),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: ValueListenableBuilder<bool>(
        valueListenable: _controller.listenerGrantedNotifier,
        builder: (context, granted, _) {
          if (!granted) {
            return PermissionPromptPage(controller: _controller);
          }
          return AppShell(controller: _controller);
        },
      ),
    );
  }
}
