import 'dart:convert';
import '../models/user_settings.dart';
import 'api_service.dart';

class SettingsService {
  final ApiService _api;

  SettingsService(this._api);

  Future<UserSettings> getSettings() async {
    final response = await _api.get('/settings');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return UserSettings.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load settings');
  }

  Future<UserSettings> updateSettings(UserSettings settings) async {
    final response = await _api.put('/settings', body: settings.toJson());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return UserSettings.fromJson(data['settings']);
    }
    throw Exception(data['message'] ?? 'Failed to update settings');
  }

  Future<void> updatePassword(String currentPassword, String newPassword, String confirmation) async {
    final response = await _api.put('/settings/password', body: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmation,
    });
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update password');
    }
  }

  Future<Map<String, dynamic>> getOAuthStatus() async {
    final response = await _api.get('/oauth/status');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load OAuth status');
  }

  Future<void> disconnectGoogle() async {
    final response = await _api.delete('/oauth/google');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to disconnect Google');
    }
  }
}
