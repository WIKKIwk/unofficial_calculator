import 'package:flutter_test/flutter_test.dart';

import 'package:notif_hub/models/captured_notification.dart';
import 'package:notif_hub/models/transaction_record.dart';
import 'package:notif_hub/models/transaction_summary.dart';
import 'package:notif_hub/models/transaction_types.dart';
import 'package:notif_hub/services/notification_transaction_parser.dart';

void main() {
  test('parses a debit grocery transaction from notification text', () async {
    const parser = NotificationTransactionParser();
    final notification = CapturedNotification(
      receivedAt: DateTime(2026, 4, 28, 10, 30),
      packageName: 'uz.kapitalbank.android',
      title: 'Korzinka',
      content: "120 000 so'm yechildi",
    );

    final record = await parser.parse(notification);

    expect(record, isNotNull);
    expect(record?.amount, 120000);
    expect(record?.direction, TransactionDirection.debit);
    expect(record?.category, TransactionCategory.groceries);
    expect(record?.merchantName, isNotNull);
    expect(record?.confidence, greaterThan(0.5));
  });

  test('parses a credit transaction from notification text', () async {
    const parser = NotificationTransactionParser();
    final notification = CapturedNotification(
      receivedAt: DateTime(2026, 4, 28, 11, 0),
      packageName: 'uz.dida.p2me',
      title: 'Payme',
      content: "Hisobingizga 250 000 so'm tushdi",
    );

    final record = await parser.parse(notification);

    expect(record, isNotNull);
    expect(record?.amount, 250000);
    expect(record?.direction, TransactionDirection.credit);
  });

  test('builds a summary with category percentages', () {
    final records = <TransactionRecord>[
      TransactionRecord(
        id: '1',
        receivedAt: DateTime(2026, 4, 28, 9, 0),
        packageName: 'uz.kapitalbank.android',
        rawTitle: 'Korzinka',
        rawContent: "100 000 so'm yechildi",
        amount: 100000,
        currency: 'UZS',
        direction: TransactionDirection.debit,
        category: TransactionCategory.groceries,
        confidence: 0.9,
        merchantName: 'Korzinka',
      ),
      TransactionRecord(
        id: '2',
        receivedAt: DateTime(2026, 4, 28, 10, 0),
        packageName: 'uz.kapitalbank.android',
        rawTitle: 'Yandex',
        rawContent: "50 000 so'm yechildi",
        amount: 50000,
        currency: 'UZS',
        direction: TransactionDirection.debit,
        category: TransactionCategory.transport,
        confidence: 0.9,
        merchantName: 'Yandex',
      ),
      TransactionRecord(
        id: '3',
        receivedAt: DateTime(2026, 4, 28, 11, 0),
        packageName: 'uz.dida.p2me',
        rawTitle: 'Payme',
        rawContent: "20 000 so'm tushdi",
        amount: 20000,
        currency: 'UZS',
        direction: TransactionDirection.credit,
        category: TransactionCategory.income,
        confidence: 0.8,
      ),
    ];

    final summary = TransactionSummary.fromRecords(records);

    expect(summary.totalCount, 3);
    expect(summary.debitTotal, 150000);
    expect(summary.creditTotal, 20000);
    expect(summary.topCategory, TransactionCategory.groceries);
    expect(summary.categoryBreakdown.first.share, closeTo(66.666, 0.1));
    expect(summary.topMerchant, 'Korzinka');
  });
}
