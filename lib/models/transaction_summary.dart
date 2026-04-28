import 'transaction_record.dart';
import 'transaction_types.dart';

class CategorySpend {
  CategorySpend({
    required this.category,
    required this.amount,
    required this.share,
  });

  final TransactionCategory category;
  final double amount;
  final double share;
}

class MerchantSpend {
  MerchantSpend({
    required this.merchant,
    required this.amount,
    required this.share,
  });

  final String merchant;
  final double amount;
  final double share;
}

class TransactionSummary {
  TransactionSummary({
    required this.totalCount,
    required this.debitTotal,
    required this.creditTotal,
    required this.netFlow,
    required this.categoryBreakdown,
    required this.merchantBreakdown,
  });

  final int totalCount;
  final double debitTotal;
  final double creditTotal;
  final double netFlow;
  final List<CategorySpend> categoryBreakdown;
  final List<MerchantSpend> merchantBreakdown;

  TransactionCategory? get topCategory =>
      categoryBreakdown.isEmpty ? null : categoryBreakdown.first.category;

  String? get topMerchant =>
      merchantBreakdown.isEmpty ? null : merchantBreakdown.first.merchant;

  double? get topMerchantAmount =>
      merchantBreakdown.isEmpty ? null : merchantBreakdown.first.amount;

  factory TransactionSummary.fromRecords(List<TransactionRecord> records) {
    double debitTotal = 0;
    double creditTotal = 0;
    final categoryTotals = <TransactionCategory, double>{};
    final merchantTotals = <String, double>{};

    for (final record in records) {
      if (record.isDebit) {
        debitTotal += record.amount;
        categoryTotals[record.effectiveCategory] =
            (categoryTotals[record.effectiveCategory] ?? 0) + record.amount;

        final merchant = record.merchantName?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          merchantTotals[merchant] = (merchantTotals[merchant] ?? 0) +
              record.amount;
        }
      } else if (record.isCredit) {
        creditTotal += record.amount;
      }
    }

    final categoryEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final merchantEntries = merchantTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return TransactionSummary(
      totalCount: records.length,
      debitTotal: debitTotal,
      creditTotal: creditTotal,
      netFlow: creditTotal - debitTotal,
      categoryBreakdown: categoryEntries
          .map(
            (entry) => CategorySpend(
              category: entry.key,
              amount: entry.value,
              share: debitTotal == 0 ? 0 : (entry.value / debitTotal) * 100,
            ),
          )
          .toList(growable: false),
      merchantBreakdown: merchantEntries
          .map(
            (entry) => MerchantSpend(
              merchant: entry.key,
              amount: entry.value,
              share: debitTotal == 0 ? 0 : (entry.value / debitTotal) * 100,
            ),
          )
          .toList(growable: false),
    );
  }
}
