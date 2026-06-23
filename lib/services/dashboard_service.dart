import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard.dart';

class DashboardService {
  final String? Function() getToken;

  DashboardService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<Dashboard> getDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Dashboard.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load dashboard');
  }
}
