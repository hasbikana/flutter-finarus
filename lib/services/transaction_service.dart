import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/transaction.dart';
import '../models/responses.dart';

class TransactionService {
  final String? Function() getToken;

  TransactionService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<TransactionResponse> getTransactions({
    String? type,
    int? categoryId,
    int? accountId,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? perPage,
  }) async {
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    if (categoryId != null) query['category_id'] = categoryId.toString();
    if (accountId != null) query['account_id'] = accountId.toString();
    if (dateFrom != null) query['date_from'] = dateFrom;
    if (dateTo != null) query['date_to'] = dateTo;
    if (search != null) query['search'] = search;
    if (perPage != null) query['per_page'] = perPage.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/transactions')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return TransactionResponse.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load transactions');
  }

  Future<Transaction> createTransaction(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/transactions'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Transaction.fromJson(data['transaction']);
    }
    throw Exception(data['message'] ?? 'Failed to create transaction');
  }

  Future<Transaction> updateTransaction(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/transactions/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Transaction.fromJson(data['transaction']);
    }
    throw Exception(data['message'] ?? 'Failed to update transaction');
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/transactions/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete transaction');
    }
  }
}
