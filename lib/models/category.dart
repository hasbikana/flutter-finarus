class Category {
  final int id;
  final String name;
  final String type; // 'income' | 'expense' | 'both'
  final String? icon;
  final String? color;
  final int transactionsCount;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.transactionsCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      color: json['color'],
      transactionsCount: json['transactions_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'transactions_count': transactionsCount,
    };
  }
}
