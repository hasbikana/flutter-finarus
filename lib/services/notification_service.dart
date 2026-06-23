import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  SharedPreferences? _prefs;

  // Keys for SharedPreferences
  static const String _historyKey = 'notif_history';
  static const String _shownTransactionIdsKey = 'shown_transaction_ids';
  static const int _maxHistory = 50;

  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings);
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ─── History Manager ──────────────────────────────────────────────

  List<AppNotification> getHistory() {
    if (_prefs == null) return [];
    final jsonStr = _prefs!.getString(_historyKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return AppNotification.listFromJson(jsonStr);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveHistory(List<AppNotification> list) async {
    if (_prefs == null) return;
    // Keep max 50 items
    if (list.length > _maxHistory) {
      list = list.sublist(list.length - _maxHistory);
    }
    await _prefs!.setString(_historyKey, AppNotification.listToJson(list));
  }

  Future<void> addToHistory(AppNotification notif) async {
    final history = getHistory();
    history.add(notif);
    await _saveHistory(history);
  }

  Future<void> markAllAsRead() async {
    final history = getHistory();
    for (final n in history) {
      n.isRead = true;
    }
    await _saveHistory(history);
  }

  Future<void> markAsRead(String id) async {
    final history = getHistory();
    final notif = history.firstWhere(
      (n) => n.id == id,
      orElse: () => AppNotification(
        id: '', type: '', title: '', body: '', createdAt: DateTime.now(),
      ),
    );
    if (notif.id.isNotEmpty) {
      notif.isRead = true;
      await _saveHistory(history);
    }
  }

  int get unreadCount {
    return getHistory().where((n) => !n.isRead).length;
  }

  Future<void> clearHistory() async {
    await _prefs?.remove(_historyKey);
  }

  // ─── Rate Limiting: Budget ────────────────────────────────────────

  String _budgetOverKey(int budgetId) => 'budget_over_$budgetId';
  String _budgetWarningKey(int budgetId) => 'budget_warning_$budgetId';

  bool _canNotifyBudget(int budgetId, String type) {
    if (_prefs == null) return true;
    final key = type == 'over' ? _budgetOverKey(budgetId) : _budgetWarningKey(budgetId);
    final lastDate = _prefs!.getString(key);
    final today = _todayString();
    return lastDate != today;
  }

  Future<void> _markBudgetNotified(int budgetId, String type) async {
    if (_prefs == null) return;
    final key = type == 'over' ? _budgetOverKey(budgetId) : _budgetWarningKey(budgetId);
    await _prefs!.setString(key, _todayString());
  }

  // ─── Transaction Income Tracker ───────────────────────────────────

  Set<int> _getShownTransactionIds() {
    if (_prefs == null) return {};
    final jsonStr = _prefs!.getString(_shownTransactionIdsKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final List data = jsonDecode(jsonStr);
      return data.map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveShownTransactionIds(Set<int> ids) async {
    if (_prefs == null) return;
    await _prefs!.setString(_shownTransactionIdsKey, jsonEncode(ids.toList()));
  }

  bool hasShownTransaction(int transactionId) {
    return _getShownTransactionIds().contains(transactionId);
  }

  Future<void> markTransactionShown(int transactionId) async {
    final ids = _getShownTransactionIds();
    ids.add(transactionId);
    await _saveShownTransactionIds(ids);
  }

  // ─── Public Notification Methods ──────────────────────────────────

  Future<void> showBudgetOverNotification({
    required int budgetId,
    required String budgetName,
  }) async {
    if (!_initialized) return;
    if (!_canNotifyBudget(budgetId, 'over')) return;

    const androidDetails = AndroidNotificationDetails(
      'budget_over',
      'Over Budget',
      channelDescription: 'Notifikasi saat anggaran melebihi batas',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final title = 'Anggaran Melebihi Batas!';
    final body = 'Anggaran $budgetName telah melebihi batas yang ditentukan.';

    await _plugin.show(id, title, body, details);
    await _markBudgetNotified(budgetId, 'over');

    await addToHistory(AppNotification(
      id: 'budget_over_${budgetId}_$id',
      type: 'budget_over',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      payload: {'budget_id': budgetId, 'budget_name': budgetName},
    ));
  }

  Future<void> showBudgetWarningNotification({
    required int budgetId,
    required String budgetName,
    required double progress,
  }) async {
    if (!_initialized) return;
    if (!_canNotifyBudget(budgetId, 'warning')) return;

    const androidDetails = AndroidNotificationDetails(
      'budget_warning',
      'Peringatan Anggaran',
      channelDescription: 'Peringatan saat anggaran mendekati batas',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final title = 'Anggaran Hampir Habis';
    final body = 'Anggaran $budgetName sudah mencapai ${progress.toStringAsFixed(0)}%.';

    await _plugin.show(id, title, body, details);
    await _markBudgetNotified(budgetId, 'warning');

    await addToHistory(AppNotification(
      id: 'budget_warn_${budgetId}_$id',
      type: 'budget_warning',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      payload: {'budget_id': budgetId, 'budget_name': budgetName, 'progress': progress},
    ));
  }

  Future<void> showBalanceMinusNotification(double balance) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'balance_minus',
      'Saldo Minus',
      channelDescription: 'Notifikasi saat total saldo negatif',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final title = 'Perhatian! Saldo Minus';
    final body = 'Total saldo Anda saat ini ${balance < 0 ? "-" : ""}Rp ${balance.abs().toStringAsFixed(0)}. Segera periksa keuangan Anda.';

    await _plugin.show(id, title, body, details);

    await addToHistory(AppNotification(
      id: 'balance_minus_$id',
      type: 'balance_minus',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      payload: {'balance': balance},
    ));
  }

  Future<void> showIncomeNotification({
    required int transactionId,
    required double amount,
    String? description,
  }) async {
    if (!_initialized) return;
    if (hasShownTransaction(transactionId)) return;

    const androidDetails = AndroidNotificationDetails(
      'transaction_income',
      'Transaksi Masuk',
      channelDescription: 'Notifikasi pemasukan baru',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final title = 'Pemasukan Baru!';
    final body = description != null && description.isNotEmpty
        ? 'Rp ${amount.toStringAsFixed(0)} - $description'
        : 'Anda menerima Rp ${amount.toStringAsFixed(0)}.';

    await _plugin.show(id, title, body, details);
    await markTransactionShown(transactionId);

    await addToHistory(AppNotification(
      id: 'income_${transactionId}_$id',
      type: 'transaction_income',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      payload: {'transaction_id': transactionId, 'amount': amount},
    ));
  }

  // ─── Helper ───────────────────────────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
