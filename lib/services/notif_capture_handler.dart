import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../parsers/notification_parser.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotifCaptureHandler {
  static const _channel = MethodChannel('org.finarus.finarus/share');
  Timer? _timer;
  String? Function()? getToken;

  void start({required String? Function() getToken}) {
    this.getToken = getToken;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final captures = await _channel.invokeMethod<List>('getCapturedNotifications');
      if (captures == null || captures.isEmpty) return;

      debugPrint('[NotifCapture] Found ${captures.length} captured notifications');

      for (final item in captures) {
        final data = Map<String, dynamic>.from(item as Map);
        final text = data['text'] as String?;
        if (text == null || text.isEmpty) continue;

        final parsed = NotificationParser.parse(text);
        if (parsed == null) {
          debugPrint('[NotifCapture] Failed to parse: ${text.substring(0, text.length.clamp(0, 60))}');
          continue;
        }

        final success = await _submitPending(parsed.type, parsed.amount, parsed.merchant, text);
        if (success) {
          debugPrint('[NotifCapture] Submitted: ${parsed.type} ${parsed.amount}');
        }
      }
    } catch (e) {
      debugPrint('[NotifCapture] Poll error: $e');
    }
  }

  Future<bool> _submitPending(String type, double amount, String? merchant, String rawBody) async {
    final token = getToken?.call();
    if (token == null) return false;

    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pending-notifications'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          'amount': amount,
          if (merchant != null) 'merchant': merchant,
          'raw_body': rawBody,
          'notification_date': today,
          'source': 'push_notif',
        }),
      );

      final respBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[NotifCapture] POST success: ${response.statusCode}');
        return true;
      } else {
        debugPrint('[NotifCapture] POST failed: ${response.statusCode} - ${respBody['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('[NotifCapture] POST error: $e');
      return false;
    }
  }
}
