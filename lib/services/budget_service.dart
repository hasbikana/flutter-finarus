import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/budget.dart';

class BudgetService {
  final String? Function() getToken;

  BudgetService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    final query = <String, String>{};
    if (month != null) query['month'] = month.toString();
    if (year != null) query['year'] = year.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/budgets')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => Budget.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load budgets');
  }

  Future<Budget> createBudget(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/budgets'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Budget.fromJson(data['budget']);
    }
    throw Exception(data['message'] ?? 'Failed to create budget');
  }

  Future<Budget> updateBudget(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/budgets/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Budget.fromJson(data['budget']);
    }
    throw Exception(data['message'] ?? 'Failed to update budget');
  }

  Future<void> deleteBudget(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/budgets/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete budget');
    }
  }
}
