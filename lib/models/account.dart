import '../utils/convert.dart';

class Account {
  final int id;
  final String name;
  final String provider;
  final String type; // 'cash' | 'ewallet' | 'bank' | 'credit_card'
  final String? accountNumber;
  final double balance;
  final String? logo;

  Account({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    this.accountNumber,
    required this.balance,
    this.logo,
  });

  String? get logoPath => logo != null ? '/logos/$logo.png' : null;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      provider: json['provider'],
      type: json['type'],
      accountNumber: json['account_number'],
      balance: toDouble(json['balance']),
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'type': type,
      'account_number': accountNumber,
      'balance': balance,
      'logo': logo,
    };
  }
}
