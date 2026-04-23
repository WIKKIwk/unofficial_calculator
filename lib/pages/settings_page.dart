import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../app_controller.dart';
import '../utils/finance_app_heuristic.dart'
    show
        curatedSmsPackages,
        curatedUzbekistanFinancePackages,
        isCuratedSmsPackage,
        matchesFinanceHeuristic,
        matchesTrackedAppHeuristic;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<AppInfo>? _apps;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<AppInfo> _visibleApps() {
    if (_apps == null) return const [];
    return _apps!.where((a) {
      if (!matchesTrackedAppHeuristic(a.name, a.packageName)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final granted = widget.controller.listenerGranted;
        final visibleApps = _visibleApps();

        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          granted
                              ? Icons.verified_user_outlined
                              : Icons.warning_amber_rounded,
                          color: granted ? scheme.primary : scheme.error,
                        ),
                        title: Text(
                          'Bildirishnoma kirish',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            granted
                                ? 'Ruxsat faol. Kerak bo‘lsa tizim sozlamalarini qayta oching.'
                                : 'Ruxsat yo‘q. Dasturdan chiqib, ruxsat ekraniga qayting.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          widget.controller.smsPermissionGranted
                              ? Icons.sms_outlined
                              : Icons.sms_failed_outlined,
                          color: widget.controller.smsPermissionGranted
                              ? scheme.secondary
                              : scheme.error,
                        ),
                        title: Text(
                          'SMS o‘qish ruxsati',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            widget.controller.smsPermissionGranted
                                ? 'Ruxsat faol. SMS bo‘limida xabarlar o‘qiladi.'
                                : 'Ruxsat yo‘q. SMS inboxni o‘qish uchun ruxsat bering.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              await widget.controller.requestSmsPermission();
                            },
                            icon: const Icon(Icons.lock_open),
                            label: const Text('SMS ruxsatini so‘rash'),
                          ),
                        ),
                      ),
                      if (granted)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.tonalIcon(
                              onPressed: () =>
                                  widget.controller.openListenerSettings(),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text(
                                'Tizim bildirishnoma sozlamalari',
                              ),
                            ),
                          ),
                        ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: scheme.outlineVariant,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Tinglanadigan ilovalar',
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (!_loading &&
                  _error == null &&
                  _apps != null &&
                  _apps!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Ro‘yxat bank/moliya va SMS ilovalari bilan cheklangan. '
                          'Tanlash Play `id=` va kalit so‘zlar asosida ishlaydi.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          title: Text(
                            'Tanilgan bank paketlari (Play)',
                            style: textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '${curatedUzbekistanFinancePackages.length} ta',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          children: [
                            for (final e
                                in curatedUzbekistanFinancePackages.entries)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.value),
                                subtitle: Text(
                                  e.key,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          title: Text(
                            'Tanilgan SMS paketlari',
                            style: textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '${curatedSmsPackages.length} ta',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          children: [
                            for (final e in curatedSmsPackages.entries)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.value),
                                subtitle: Text(
                                  e.key,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Ilovalar ro‘yxatini yuklashda xatolik:\n$_error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (_apps == null || _apps!.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Ilovalar topilmadi')),
                )
              else ...[
                if (visibleApps.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Filtr yoki qidiruvga mos ilova yo‘q.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index.isOdd) {
                        return Divider(
                          height: 1,
                          thickness: 1,
                          color: scheme.outlineVariant,
                        );
                      }
                      final appIndex = index ~/ 2;
                      final app = visibleApps[appIndex];
                      final allowed = widget.controller.isPackageAllowed(
                        app.packageName,
                      );
                      final likelyFinance = matchesFinanceHeuristic(
                        app.name,
                        app.packageName,
                      );
                      final likelySms = isCuratedSmsPackage(app.packageName);
                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        value: allowed,
                        onChanged: (value) {
                          widget.controller.setPackageAllowed(
                            app.packageName,
                            value,
                          );
                        },
                        title: Text(
                          app.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          app.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        secondary: Icon(
                          likelyFinance
                              ? Icons.account_balance_outlined
                              : (likelySms
                                  ? Icons.sms_outlined
                                  : Icons.apps_rounded),
                          color: likelyFinance
                              ? scheme.tertiary
                              : (likelySms ? scheme.secondary : scheme.primary),
                        ),
                      );
                    }, childCount: visibleApps.length * 2 - 1),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        );
      },
    );
  }
}
