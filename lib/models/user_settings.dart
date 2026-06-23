class UserSettings {
  final bool emailNotifications;
  final bool budgetAlerts;
  final String theme; // 'light' | 'dark'
  final bool emailFetchEnabled;
  final bool balanceAlerts;
  final bool transactionAlerts;
  final bool pushNotifications;

  UserSettings({
    required this.emailNotifications,
    required this.budgetAlerts,
    required this.theme,
    required this.emailFetchEnabled,
    required this.balanceAlerts,
    required this.transactionAlerts,
    required this.pushNotifications,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      emailNotifications: json['email_notifications'] ?? true,
      budgetAlerts: json['budget_alerts'] ?? true,
      theme: json['theme'] ?? 'light',
      emailFetchEnabled: json['email_fetch_enabled'] ?? false,
      balanceAlerts: json['balance_alerts'] ?? true,
      transactionAlerts: json['transaction_alerts'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_notifications': emailNotifications,
      'budget_alerts': budgetAlerts,
      'theme': theme,
      'email_fetch_enabled': emailFetchEnabled,
      'balance_alerts': balanceAlerts,
      'transaction_alerts': transactionAlerts,
      'push_notifications': pushNotifications,
    };
  }

  UserSettings copyWith({
    bool? emailNotifications,
    bool? budgetAlerts,
    String? theme,
    bool? emailFetchEnabled,
    bool? balanceAlerts,
    bool? transactionAlerts,
    bool? pushNotifications,
  }) {
    return UserSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      theme: theme ?? this.theme,
      emailFetchEnabled: emailFetchEnabled ?? this.emailFetchEnabled,
      balanceAlerts: balanceAlerts ?? this.balanceAlerts,
      transactionAlerts: transactionAlerts ?? this.transactionAlerts,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
