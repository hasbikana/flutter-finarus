import 'dart:math';

class SavingGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? icon;
  final String? image;

  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.icon,
    this.image,
  });

  double get progress => targetAmount > 0
      ? min(100, (currentAmount / targetAmount * 100).roundToDouble())
      : 0;
  double get remaining => max(0, targetAmount - currentAmount);

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    return SavingGoal(
      id: json['id'],
      name: json['name'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      icon: json['icon'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().split('T').first,
      'icon': icon,
      'image': image,
    };
  }
}
