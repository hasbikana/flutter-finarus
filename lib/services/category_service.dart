import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category.dart';

class CategoryService {
  final String? Function() getToken;

  CategoryService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/categories'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['data'] as List).map((e) => Category.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load categories');
  }

  Future<Category> createCategory(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/categories'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(data['category']);
    }
    throw Exception(data['message'] ?? 'Failed to create category');
  }

  Future<Category> updateCategory(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/categories/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Category.fromJson(data['category']);
    }
    throw Exception(data['message'] ?? 'Failed to update category');
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/categories/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete category');
    }
  }
}
