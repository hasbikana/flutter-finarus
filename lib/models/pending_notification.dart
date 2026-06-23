class PendingNotification {
  final int id;
  final String type; // income | expense
  final double amount;
  final String? description;
  final String? merchant;
  final String notificationDate;
  final String? rawBody;
  final String? imagePath;
  final String source; // push_notif | ocr
  final String status; // pending | confirmed | rejected
  final DateTime createdAt;
  final DateTime updatedAt;

  PendingNotification({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    this.merchant,
    required this.notificationDate,
    this.rawBody,
    this.imagePath,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      merchant: json['merchant'],
      notificationDate: json['notification_date'],
      rawBody: json['raw_body'],
      imagePath: json['image_path'],
      source: json['source'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'merchant': merchant,
      'notification_date': notificationDate,
      'raw_body': rawBody,
      'image_path': imagePath,
      'source': source,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
