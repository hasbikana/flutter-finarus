import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/app_notification.dart';
import '../models/pending_notification.dart';
import '../services/notification_service.dart';
import '../services/pending_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final PendingNotificationService? _pendingService;

  NotificationProvider({this._pendingService});

  // Local notifications (budget, balance, income)
  final NotificationService _notifService = NotificationService();

  // Pending notifications from server
  List<PendingNotification> _pendingItems = [];
  bool _pendingLoading = false;
  String? _pendingError;
  String? _lastActionError;

  List<PendingNotification> get pendingItems => _pendingItems;
  bool get pendingLoading => _pendingLoading;
  String? get pendingError => _pendingError;
  String? get lastActionError => _lastActionError;

  // Local history
  List<AppNotification> get localHistory => _notifService.getHistory();
  int get localUnreadCount => _notifService.unreadCount;

  // Total unread (local + pending)
  int get totalUnreadCount => localUnreadCount + _pendingItems.length;

  // ─── Check & Notify from Dashboard ────────────────────────────────

  void checkAndNotifyBudget(List<Budget> budgets) {
    for (final budget in budgets) {
      final name = budget.category?.name ?? 'Anggaran';
      if (budget.isOverBudget) {
        _notifService.showBudgetOverNotification(
          budgetId: budget.id,
          budgetName: name,
        );
      } else if (budget.progress >= 80) {
        _notifService.showBudgetWarningNotification(
          budgetId: budget.id,
          budgetName: name,
          progress: budget.progress,
        );
      }
    }
    notifyListeners(); // history changed
  }

  void checkAndNotifyBalance(double balance) {
    if (balance < 0) {
      _notifService.showBalanceMinusNotification(balance);
      notifyListeners();
    }
  }

  void checkAndNotifyNewTransactions(List<Transaction> transactions) {
    for (final tx in transactions) {
      if (tx.type == 'income') {
        _notifService.showIncomeNotification(
          transactionId: tx.id,
          amount: tx.amount,
          description: tx.description,
        );
      }
    }
    notifyListeners();
  }

  // ─── Local History Management ─────────────────────────────────────

  Future<void> markAllLocalAsRead() async {
    await _notifService.markAllAsRead();
    notifyListeners();
  }

  Future<void> markLocalAsRead(String id) async {
    await _notifService.markAsRead(id);
    notifyListeners();
  }

  Future<void> clearLocalHistory() async {
    await _notifService.clearHistory();
    notifyListeners();
  }

  // ─── Pending Notifications from Server ────────────────────────────

  Future<void> fetchPending() async {
    if (_pendingService == null) return;
    _pendingLoading = true;
    _pendingError = null;
    notifyListeners();

    try {
      _pendingItems = await _pendingService.getPendingNotifications();
      debugPrint('Pending notifications loaded: ${_pendingItems.length} items');
    } catch (e) {
      _pendingError = e.toString();
      debugPrint('Failed to load pending notifications: $_pendingError');
    }

    _pendingLoading = false;
    notifyListeners();
  }

  Future<bool> approvePending(int id, int categoryId, int accountId, {String? description}) async {
    if (_pendingService == null) return false;
    _lastActionError = null;
    try {
      debugPrint('[ApprovePending] Approving id=$id, cat=$categoryId, acc=$accountId');
      await _pendingService.approvePendingNotification(
        id: id,
        categoryId: categoryId,
        accountId: accountId,
        description: description,
      );
      _pendingItems.removeWhere((p) => p.id == id);
      notifyListeners();
      debugPrint('[ApprovePending] Success: id=$id removed from list');
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      debugPrint('[ApprovePending] Error: $_lastActionError');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectPending(int id) async {
    if (_pendingService == null) return false;
    _lastActionError = null;
    try {
      debugPrint('[RejectPending] Rejecting id=$id');
      await _pendingService.rejectPendingNotification(id);
      _pendingItems.removeWhere((p) => p.id == id);
      notifyListeners();
      debugPrint('[RejectPending] Success: id=$id');
      return true;
    } catch (e) {
      _lastActionError = e.toString();
      debugPrint('[RejectPending] Error: $_lastActionError');
      notifyListeners();
      return false;
    }
  }
}
