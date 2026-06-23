import 'transaction.dart';
import 'budget.dart';

import '../utils/convert.dart';

class Dashboard {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final int activeSavingGoals;
  final List<Transaction> recentTransactions;
  final List<Budget> budgetProgress;

  Dashboard({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.activeSavingGoals,
    required this.recentTransactions,
    required this.budgetProgress,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      balance: toDouble(json['balance']),
      totalIncome: toDouble(json['total_income']),
      totalExpense: toDouble(json['total_expense']),
      activeSavingGoals: json['active_saving_goals'] ?? 0,
      recentTransactions: (json['recent_transactions'] as List?)
          ?.map((e) => Transaction.fromJson(e))
          .toList() ?? [],
      budgetProgress: (json['budget_progress'] as List?)
          ?.map((e) => Budget.fromJson(e))
          .toList() ?? [],
    );
  }
}
