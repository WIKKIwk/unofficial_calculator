import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/transaction_record.dart';
import '../models/transaction_types.dart';
import 'transaction_detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.controller});

  final AppController controller;

  String _formatMoney(double value) {
    final fixed = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < fixed.length; i++) {
      final indexFromEnd = fixed.length - i;
      buffer.write(fixed[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString().trimRight();
  }

  String _formatShare(double value) => value.toStringAsFixed(1);

  Color _categoryColor(ColorScheme scheme, int index) {
    final colors = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.primaryContainer,
      scheme.secondaryContainer,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: controller.transactionLedger,
      builder: (context, _) {
        final summary = controller.transactionLedger.summary;
        final categories = summary.categoryBreakdown;
        final merchants = summary.merchantBreakdown;
        final hasData = summary.totalCount > 0;

        if (!hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              _HeroCard(
                scheme: scheme,
                title: 'Transaction dashboard',
                subtitle:
                    'Bank notificationlar kelgach, xarajat turlari va foizlar shu yerda chiqadi.',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                scheme: scheme,
                title: 'Hozircha ma’lumot yo‘q',
                body:
                    'Birinchi transaction notif kelgandan keyin dashboard avtomatik to‘ladi.',
                icon: Icons.hourglass_empty_rounded,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                scheme: scheme,
                title: 'AI fallback faol',
                body: controller.geminiConfigured
                    ? 'Gemini Flash API key saqlandi.'
                    : 'Gemini API key hali kiritilmagan, local heuristic ishlayapti.',
                icon: controller.geminiConfigured
                    ? Icons.psychology_alt_outlined
                    : Icons.auto_awesome_outlined,
              ),
            ],
          );
        }

        final topCategory = summary.topCategory;
        final topMerchant = summary.topMerchant;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            _HeroCard(
              scheme: scheme,
              title: 'Xarajat dashboardi',
              subtitle:
                  'Transaction oqimi bo‘yicha umumiy ko‘rinish va eng katta sarflar.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    scheme: scheme,
                    title: 'Debit',
                    value: _formatMoney(summary.debitTotal),
                    icon: Icons.trending_down_rounded,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    scheme: scheme,
                    title: 'Credit',
                    value: _formatMoney(summary.creditTotal),
                    icon: Icons.trending_up_rounded,
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricCard(
              scheme: scheme,
              title: 'Net flow',
              value: _formatMoney(summary.netFlow.abs()),
              icon: summary.netFlow >= 0
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: summary.netFlow >= 0 ? scheme.error : scheme.primary,
              trailing: Text(
                summary.netFlow >= 0 ? 'Outflow' : 'Inflow',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MetricCard(
              scheme: scheme,
              title: 'Transactions',
              value: summary.totalCount.toString(),
              icon: Icons.receipt_long_outlined,
              color: scheme.tertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Kategoriya bo‘yicha',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              _EmptySection(
                scheme: scheme,
                title: 'Kategoriya yo‘q',
                body: 'AI yoki heuristika hali xarajatlarni kategoriyalamadi.',
              )
            else
              ...categories.asMap().entries.map((entry) {
                final index = entry.key;
                final spend = entry.value;
                final color = _categoryColor(scheme, index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BreakdownCard(
                    scheme: scheme,
                    title: spend.category.label,
                    amount: _formatMoney(spend.amount),
                    share: _formatShare(spend.share),
                    progress: (spend.share / 100).clamp(0.0, 1.0),
                    color: color,
                  ),
                );
              }),
            const SizedBox(height: 12),
            if (topCategory != null)
              _InfoCard(
                scheme: scheme,
                title: 'Eng ko‘p ketayotgan yo‘nalish',
                body:
                    '${topCategory.label} eng katta ulushni egallayapti.',
                icon: Icons.insights_outlined,
              ),
            const SizedBox(height: 20),
            Text(
              'Merchant bo‘yicha',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (merchants.isEmpty)
              _EmptySection(
                scheme: scheme,
                title: 'Merchant yo‘q',
                body: 'Merchant nomi aniqlanganda bu bo‘lim to‘ladi.',
              )
            else
              ...merchants.take(5).map((spend) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BreakdownCard(
                    scheme: scheme,
                    title: spend.merchant,
                    amount: _formatMoney(spend.amount),
                    share: _formatShare(spend.share),
                    progress: (spend.share / 100).clamp(0.0, 1.0),
                    color: scheme.secondary,
                    subtitle: 'Merchant spend',
                  ),
                );
              }),
            const SizedBox(height: 12),
            if (topMerchant != null)
              _InfoCard(
                scheme: scheme,
                title: 'Eng katta merchant',
                body:
                    '$topMerchant ga ${_formatMoney(summary.topMerchantAmount ?? 0)} ketgan.',
                icon: Icons.storefront_outlined,
              ),
            const SizedBox(height: 20),
            Text(
              'So‘nggi transactionlar',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.transactions.isEmpty)
              _EmptySection(
                scheme: scheme,
                title: 'Transaction yo‘q',
                body: 'Yangi bank notif kelgach, bu yerda oxirgi yozuvlar chiqadi.',
              )
            else
              ...controller.transactions.take(8).map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentTransactionCard(
                    scheme: scheme,
                    record: record,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailPage(
                            controller: controller,
                            record: record,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.scheme,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final ColorScheme scheme;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.9),
            scheme.secondaryContainer.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: scheme.onSurface, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.scheme,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trailing,
  });

  final ColorScheme scheme;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
              if (trailing != null) ...[trailing!],
              ],
            ),
          const SizedBox(height: 14),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.scheme,
    required this.title,
    required this.amount,
    required this.share,
    required this.progress,
    required this.color,
    this.subtitle,
  });

  final ColorScheme scheme;
  final String title;
  final String amount;
  final String share;
  final double progress;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$share%',
                style: textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: scheme.outlineVariant.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.scheme,
    required this.title,
    required this.body,
    required this.icon,
  });

  final ColorScheme scheme;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.scheme,
    required this.title,
    required this.body,
  });

  final ColorScheme scheme;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionCard extends StatelessWidget {
  const _RecentTransactionCard({
    required this.scheme,
    required this.record,
    required this.onTap,
  });

  final ColorScheme scheme;
  final TransactionRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: record.isDebit
                  ? scheme.errorContainer
                  : scheme.secondaryContainer,
              foregroundColor: scheme.onSurface,
              child: Icon(
                record.isDebit
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.merchantName?.trim().isNotEmpty == true
                        ? record.merchantName!.trim()
                        : record.packageName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.effectiveCategory.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${record.amount.round()} ${record.currency}',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
