import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;

  UserSettings? _settings;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _oauthStatus;

  SettingsProvider(this._service);

  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGoogleConnected => _oauthStatus?['connected'] == true;
  String? get googleEmail => _oauthStatus?['email'];

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _service.getSettings();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOAuthStatus() async {
    try {
      _oauthStatus = await _service.getOAuthStatus();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> disconnectGoogle() async {
    try {
      await _service.disconnectGoogle();
      _oauthStatus = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSettings(UserSettings settings) async {
    try {
      _settings = await _service.updateSettings(settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(
      String currentPassword, String newPassword, String confirmation) async {
    try {
      await _service.updatePassword(currentPassword, newPassword, confirmation);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
