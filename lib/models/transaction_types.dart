enum TransactionDirection {
  debit,
  credit,
  transfer,
  fee,
  refund,
  cashWithdrawal,
  unknown,
}

extension TransactionDirectionX on TransactionDirection {
  String get label => switch (this) {
        TransactionDirection.debit => 'Debit',
        TransactionDirection.credit => 'Credit',
        TransactionDirection.transfer => 'Transfer',
        TransactionDirection.fee => 'Fee',
        TransactionDirection.refund => 'Refund',
        TransactionDirection.cashWithdrawal => 'Cash withdrawal',
        TransactionDirection.unknown => 'Unknown',
      };
}

enum TransactionCategory {
  groceries,
  food,
  transport,
  shopping,
  utilities,
  mobileTopUp,
  cashWithdrawal,
  transfer,
  fees,
  income,
  entertainment,
  health,
  education,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get label => switch (this) {
        TransactionCategory.groceries => 'Groceries',
        TransactionCategory.food => 'Food',
        TransactionCategory.transport => 'Transport',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.utilities => 'Utilities',
        TransactionCategory.mobileTopUp => 'Mobile top-up',
        TransactionCategory.cashWithdrawal => 'Cash withdrawal',
        TransactionCategory.transfer => 'Transfer',
        TransactionCategory.fees => 'Fees',
        TransactionCategory.income => 'Income',
        TransactionCategory.entertainment => 'Entertainment',
        TransactionCategory.health => 'Health',
        TransactionCategory.education => 'Education',
        TransactionCategory.other => 'Other',
      };
}

