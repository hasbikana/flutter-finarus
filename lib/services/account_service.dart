import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/account.dart';
import '../models/responses.dart';

class AccountService {
  final String? Function() getToken;

  AccountService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<AccountListResponse> getAccounts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/accounts'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return AccountListResponse.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load accounts');
  }

  Future<Account> createAccount(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/accounts'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Account.fromJson(data['account']);
    }
    throw Exception(data['message'] ?? 'Failed to create account');
  }

  Future<Account> updateAccount(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/accounts/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Account.fromJson(data['account']);
    }
    throw Exception(data['message'] ?? 'Failed to update account');
  }

  Future<void> deleteAccount(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/accounts/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete account');
    }
  }
}
