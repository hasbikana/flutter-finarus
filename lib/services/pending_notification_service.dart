import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      return data['pending_count'] ?? data['count'] ?? 0;
    }
    throw Exception(data['message'] ?? 'Failed to load pending count');
  }

  Future<void> approvePendingNotification({
    required int id,
    required int categoryId,
    required int accountId,
    String? description,
  }) async {
    debugPrint('[PendingService] PATCH /pending-notifications/$id/approve');
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/pending-notifications/$id/approve'),
      headers: _headers,
      body: jsonEncode({
        'category_id': categoryId,
        'account_id': accountId,
        if (description != null) 'description': description,
      }),
    );
    debugPrint('[PendingService] Approve response: ${response.statusCode} - ${response.body}');
    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(_extractMessage(response));
    }
  }

  Future<void> rejectPendingNotification(int id) async {
    debugPrint('[PendingService] DELETE /pending-notifications/$id/reject');
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/pending-notifications/$id/reject'),
      headers: _headers,
    );
    debugPrint('[PendingService] Reject response: ${response.statusCode} - ${response.body}');
    if (!_isSuccessStatus(response.statusCode)) {
      throw Exception(_extractMessage(response));
    }
  }

  static bool _isSuccessStatus(int statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 204;
  }

  static String _extractMessage(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return 'Request failed with status ${response.statusCode}';
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return 'Request failed with status ${response.statusCode}';
  }
}
