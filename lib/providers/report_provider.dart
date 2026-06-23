import 'dart:io';
import 'package:flutter/material.dart';
import '../models/responses.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  MonthlyReport? _monthlyReport;
  CategoryReport? _categoryReport;
  TrendReport? _trendReport;
  bool _isLoading = false;
  String? _error;
  int _selectedMonth;
  int _selectedYear;

  ReportProvider(this._service)
      : _selectedMonth = DateTime.now().month,
        _selectedYear = DateTime.now().year;

  MonthlyReport? get monthlyReport => _monthlyReport;
  CategoryReport? get categoryReport => _categoryReport;
  TrendReport? get trendReport => _trendReport;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void setMonth(int month) {
    _selectedMonth = month;
    loadReports();
  }

  void setYear(int year) {
    _selectedYear = year;
    loadReports();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _monthlyReport = await _service.getMonthlyReport(
        month: _selectedMonth,
        year: _selectedYear,
      );
      _categoryReport = await _service.getCategoryReport(
        month: _selectedMonth,
        year: _selectedYear,
      );
      _trendReport = await _service.getTrendReport(year: _selectedYear);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<File?> downloadExport(String format) async {
    try {
      return await _service.downloadExport(
        format: format,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
