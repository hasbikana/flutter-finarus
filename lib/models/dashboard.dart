import 'transaction.dart';
import 'budget.dart';

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
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
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
