import 'dart:math';

import 'category.dart';

import '../utils/convert.dart';

class Budget {
  final int id;
  final int categoryId;
  final double amount;
  final int month;
  final int year;
  final Category? category;

  // Computed (filled by provider/screen logic)
  double spent;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    this.category,
    this.spent = 0,
  });

  double get progress => amount > 0 ? min(100, (spent / amount * 100)) : 0;
  bool get isOverBudget => spent > amount;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['category_id'] ?? json['category']?['id'],
      amount: toDouble(json['amount']),
      month: json['month'],
      year: json['year'],
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }
}
