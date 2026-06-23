import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pending_notification.dart';

class PendingNotificationService {
  final String? Function() getToken;

  PendingNotificationService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<PendingNotification>> getPendingNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pending-notifications'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final List items = data['data'] ?? data;
      return items.map((e) => PendingNotification.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load pending notifications');
  }

  Future<int> getPendingCount() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pending-notifications/count'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['count'] ?? 0;
    }
    throw Exception(data['message'] ?? 'Failed to load pending count');
  }

  Future<void> approvePendingNotification({
    required int id,
    required int categoryId,
    required int accountId,
    String? description,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/pending-notifications/$id/approve'),
      headers: _headers,
      body: jsonEncode({
        'category_id': categoryId,
        'account_id': accountId,
        if (description != null) 'description': description,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to approve pending notification');
    }
  }

  Future<void> rejectPendingNotification(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/pending-notifications/$id/reject'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to reject pending notification');
    }
  }
}
