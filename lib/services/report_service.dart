import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/responses.dart';

class ReportService {
  final String? Function() getToken;

  ReportService(this.getToken);

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<MonthlyReport> getMonthlyReport({int? month, int? year}) async {
    final query = <String, String>{};
    if (month != null) query['month'] = month.toString();
    if (year != null) query['year'] = year.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/reports/monthly')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MonthlyReport.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load monthly report');
  }

  Future<CategoryReport> getCategoryReport({
    String type = 'expense',
    int? month,
    int? year,
  }) async {
    final query = <String, String>{'type': type};
    if (month != null) query['month'] = month.toString();
    if (year != null) query['year'] = year.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/reports/categories')
        .replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return CategoryReport.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load category report');
  }

  Future<TrendReport> getTrendReport({int? year}) async {
    final query = <String, String>{};
    if (year != null) query['year'] = year.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/reports/trend')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return TrendReport.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load trend report');
  }

  Future<File> downloadExport({String format = 'csv', int? month, int? year}) async {
    final query = <String, String>{'format': format};
    if (month != null) query['month'] = month.toString();
    if (year != null) query['year'] = year.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/reports/export')
        .replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengunduh laporan');
    }

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/finarus_laporan_${year ?? DateTime.now().year}_${month ?? DateTime.now().month}.$format');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
