import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;

  Dashboard? _dashboard;
  bool _isLoading = false;
  String? _error;

  DashboardProvider(this._service);

  Dashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _service.getDashboard();
      if (_dashboard == null) {
        _error = 'Data dashboard kosong';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Dashboard load error: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }
}
