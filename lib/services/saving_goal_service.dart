import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/saving_goal.dart';

class SavingGoalService {
  final String? Function() getToken;

  SavingGoalService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<SavingGoal>> getSavingGoals() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/saving-goals'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => SavingGoal.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load saving goals');
  }

  Future<SavingGoal> createSavingGoal(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/saving-goals'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SavingGoal.fromJson(data['saving_goal']);
    }
    throw Exception(data['message'] ?? 'Failed to create saving goal');
  }

  Future<SavingGoal> updateSavingGoal(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/saving-goals/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return SavingGoal.fromJson(data['saving_goal']);
    }
    throw Exception(data['message'] ?? 'Failed to update saving goal');
  }

  Future<void> deleteSavingGoal(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/saving-goals/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete saving goal');
    }
  }
}
