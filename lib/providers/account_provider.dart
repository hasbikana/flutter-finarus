import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_service.dart';

class AccountProvider extends ChangeNotifier {
  final AccountService _service;

  List<Account> _accounts = [];
  double _totalBalance = 0;
  int _totalAccounts = 0;
  bool _isLoading = false;
  String? _error;

  AccountProvider(this._service);

  List<Account> get accounts => _accounts;
  double get totalBalance => _totalBalance;
  int get totalAccounts => _totalAccounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Account> get bankAccounts =>
      _accounts.where((a) => a.type == 'bank').toList();
  List<Account> get ewalletAccounts =>
      _accounts.where((a) => a.type == 'ewallet').toList();
  List<Account> get creditCardAccounts =>
      _accounts.where((a) => a.type == 'credit_card').toList();
  Account? get cashAccount =>
      _accounts.cast<Account?>().firstWhere((a) => a?.type == 'cash', orElse: () => null);

  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getAccounts();
      _accounts = response.data;
      _totalBalance = response.totalBalance;
      _totalAccounts = response.totalAccounts;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAccount(Map<String, dynamic> body) async {
    try {
      await _service.createAccount(body);
      await loadAccounts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> body) async {
    try {
      await _service.updateAccount(id, body);
      await loadAccounts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      await _service.deleteAccount(id);
      await loadAccounts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
