import 'package:flutter/material.dart';
import '../models/saving_goal.dart';
import '../services/saving_goal_service.dart';

class SavingGoalProvider extends ChangeNotifier {
  final SavingGoalService _service;

  List<SavingGoal> _goals = [];
  bool _isLoading = false;
  String? _error;

  SavingGoalProvider(this._service);

  List<SavingGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await _service.getSavingGoals();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createGoal(Map<String, dynamic> body) async {
    try {
      await _service.createSavingGoal(body);
      await loadGoals();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGoal(int id, Map<String, dynamic> body) async {
    try {
      await _service.updateSavingGoal(id, body);
      await loadGoals();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await _service.deleteSavingGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
