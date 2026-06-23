import 'transaction.dart';
import 'account.dart';
import '../utils/convert.dart';

class TransactionResponse {
  final List<Transaction> data;
  final int currentPage;
  final int lastPage;
  final int total;

  TransactionResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      data: (json['data'] as List)
          .map((e) => Transaction.fromJson(e))
          .toList(),
      currentPage: json['meta']?['current_page'] ?? json['current_page'],
      lastPage: json['meta']?['last_page'] ?? json['last_page'],
      total: json['meta']?['total'] ?? json['total'],
    );
  }
}

class AccountListResponse {
  final List<Account> data;
  final double totalBalance;
  final int totalAccounts;

  AccountListResponse({
    required this.data,
    required this.totalBalance,
    required this.totalAccounts,
  });

  factory AccountListResponse.fromJson(Map<String, dynamic> json) {
    return AccountListResponse(
      data: (json['data'] as List)
          .map((e) => Account.fromJson(e))
          .toList(),
      totalBalance: toDouble(json['meta']?['total_balance']),
      totalAccounts: json['meta']['total_accounts'],
    );
  }
}

class MonthlyReport {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int month;
  final int year;

  MonthlyReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.month,
    required this.year,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      totalIncome: toDouble(json['total_income']),
      totalExpense: toDouble(json['total_expense']),
      balance: toDouble(json['balance']),
      month: json['month'],
      year: json['year'],
    );
  }
}

class TrendPoint {
  final int month;
  final String monthName;
  final double income;
  final double expense;
  final double net;

  TrendPoint({
    required this.month,
    required this.monthName,
    required this.income,
    required this.expense,
    required this.net,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      month: json['month'],
      monthName: json['month_name'],
      income: toDouble(json['income']),
      expense: toDouble(json['expense']),
      net: toDouble(json['net']),
    );
  }
}

class TrendReport {
  final int year;
  final List<TrendPoint> trend;

  TrendReport({
    required this.year,
    required this.trend,
  });

  factory TrendReport.fromJson(Map<String, dynamic> json) {
    return TrendReport(
      year: json['year'],
      trend: (json['trend'] as List)
          .map((e) => TrendPoint.fromJson(e))
          .toList(),
    );
  }
}

class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double total;

  CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.total,
  });

  factory CategoryTotal.fromJson(Map<String, dynamic> json) {
    return CategoryTotal(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      categoryColor: json['category_color'],
      total: toDouble(json['total']),
    );
  }
}

class CategoryReport {
  final String type;
  final int month;
  final int year;
  final List<CategoryTotal> categories;

  CategoryReport({
    required this.type,
    required this.month,
    required this.year,
    required this.categories,
  });

  factory CategoryReport.fromJson(Map<String, dynamic> json) {
    return CategoryReport(
      type: json['type'],
      month: json['month'],
      year: json['year'],
      categories: (json['categories'] as List)
          .map((e) => CategoryTotal.fromJson(e))
          .toList(),
    );
  }
}
