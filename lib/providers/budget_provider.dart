import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service;

  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;
  int _selectedMonth;
  int _selectedYear;

  BudgetProvider(this._service)
      : _selectedMonth = DateTime.now().month,
        _selectedYear = DateTime.now().year;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void setMonth(int month) {
    _selectedMonth = month;
    loadBudgets();
  }

  void setYear(int year) {
    _selectedYear = year;
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _budgets = await _service.getBudgets(
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBudget(Map<String, dynamic> body) async {
    try {
      await _service.createBudget(body);
      await loadBudgets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBudget(int id, Map<String, dynamic> body) async {
    try {
      await _service.updateBudget(id, body);
      await loadBudgets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      await _service.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
