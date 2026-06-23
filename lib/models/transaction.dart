import 'category.dart';
import 'account.dart';
import 'saving_goal.dart';

import '../utils/convert.dart';

class Transaction {
  final int id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final String? emailMessageId;
  final String? source;
  final int categoryId;
  final int? accountId;
  final int? savingGoalId;

  // Relationships (loaded via API Resource)
  final Category? category;
  final Account? account;
  final SavingGoal? savingGoal;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.transactionDate,
    this.emailMessageId,
    this.source,
    required this.categoryId,
    this.accountId,
    this.savingGoalId,
    this.category,
    this.account,
    this.savingGoal,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: toDouble(json['amount']),
      description: json['description'],
      transactionDate: DateTime.parse(json['transaction_date']),
      emailMessageId: json['email_message_id'],
      source: json['source'],
      categoryId: json['category_id'] ?? json['category']?['id'],
      accountId: json['account_id'] ?? json['account']?['id'],
      savingGoalId: json['saving_goal_id'] ?? json['saving_goal']?['id'],
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      account: json['account'] != null
          ? Account.fromJson(json['account'])
          : null,
      savingGoal: json['saving_goal'] != null
          ? SavingGoal.fromJson(json['saving_goal'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'email_message_id': emailMessageId,
      'source': source,
      'category_id': categoryId,
      'account_id': accountId,
      'saving_goal_id': savingGoalId,
    };
  }
}
