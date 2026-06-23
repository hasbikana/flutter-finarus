import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _service;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  // Filters
  String? _typeFilter;
  int? _categoryIdFilter;
  String? _searchQuery;

  TransactionProvider(this._service);

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;

  String? get typeFilter => _typeFilter;
  int? get categoryIdFilter => _categoryIdFilter;
  String? get searchQuery => _searchQuery;

  void setTypeFilter(String? type) {
    _typeFilter = type;
    _transactions = [];
    _currentPage = 1;
    loadTransactions();
  }

  void setCategoryIdFilter(int? id) {
    _categoryIdFilter = id;
    _transactions = [];
    _currentPage = 1;
    loadTransactions();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    _transactions = [];
    _currentPage = 1;
    loadTransactions();
  }

  Future<void> loadTransactions({bool loadMore = false}) async {
    if (_isLoading) return;

    if (loadMore && !hasMore) return;

    _isLoading = true;
    _error = null;
    if (!loadMore) notifyListeners();

    try {
      final page = _currentPage + (loadMore ? 1 : 0);
      if (loadMore) _currentPage = page;
      final response = await _service.getTransactions(
        type: _typeFilter,
        categoryId: _categoryIdFilter,
        search: _searchQuery,
        perPage: 20,
      );

      if (loadMore) {
        _transactions.addAll(response.data);
      } else {
        _transactions = response.data;
      }
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      _total = response.total;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTransaction(Map<String, dynamic> body) async {
    try {
      await _service.createTransaction(body);
      _transactions = [];
      _currentPage = 1;
      await loadTransactions();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(int id, Map<String, dynamic> body) async {
    try {
      await _service.updateTransaction(id, body);
      _transactions = [];
      _currentPage = 1;
      await loadTransactions();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _service.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _total--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
