import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/transaction_record.dart';
import '../models/transaction_types.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({
    super.key,
    required this.controller,
    required this.record,
  });

  final AppController controller;
  final TransactionRecord record;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late TransactionCategory _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.record.userCategory ?? widget.record.category;
  }

  String _formatMoney(double value) => value.round().toString();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final record = widget.record;
    final isDebit = record.isDebit;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDebit
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: isDebit ? scheme.error : scheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record.merchantName?.trim().isNotEmpty == true
                            ? record.merchantName!.trim()
                            : record.packageName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_formatMoney(record.amount)} ${record.currency}',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.rawContent,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI suggestion',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Direction', value: record.direction.label),
          _DetailRow(label: 'Category', value: record.category.label),
          _DetailRow(
            label: 'User category',
            value: record.userCategory?.label ?? 'Not reviewed',
          ),
          _DetailRow(label: 'Confidence', value: '${(record.confidence * 100).toStringAsFixed(0)}%'),
          _DetailRow(
            label: 'Package',
            value: record.packageName,
          ),
          if (record.balanceAfter != null)
            _DetailRow(
              label: 'Balance after',
              value: '${_formatMoney(record.balanceAfter!)} ${record.currency}',
            ),
          if (record.cardLast4 != null)
            _DetailRow(label: 'Card', value: '**** ${record.cardLast4}'),
          const SizedBox(height: 20),
          Text(
            'Category review',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TransactionCategory>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'This transaction was for',
            ),
            items: TransactionCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selected = value;
              });
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await widget.controller.reviewTransaction(record.id, _selected);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Feedback saved')),
              );
              navigator.pop();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save review'),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu tanlov keyingi o‘xshash transactionlarni yaxshiroq kategoriyalashga yordam beradi.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
