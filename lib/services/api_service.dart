import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    return await http.get(uri, headers: _headers);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    return await http.put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String path) async {
    return await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );
  }

  Future<http.StreamedResponse> multipartPost(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$path'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields.addAll(fields);
    request.files.addAll(files);
    return await request.send();
  }
}
