import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: ApiConfig.googleWebClientId,
  );

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _setLoading(true);
    try {
      _token = await _storage.read(key: 'token');
      if (_token != null) {
        _user = await _authService.me(_token!);
      }
    } catch (e) {
      _token = null;
      _user = null;
      await _storage.delete(key: 'token');
    }
    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _authService.login(email, password);
      _token = data['token'];
      await _storage.write(key: 'token', value: _token);
      _user = User.fromJson(data['user']);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    _setLoading(true);
    try {
      final data = await _authService.register(
        name,
        email,
        password,
        passwordConfirmation,
      );
      _token = data['token'];
      await _storage.write(key: 'token', value: _token);
      _user = User.fromJson(data['user']);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> googleLogin() async {
    _setLoading(true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _setLoading(false);
        return false;
      }
      final auth = await account.authentication;
      final data = await _authService.googleLogin(auth.idToken!);
      _token = data['token'];
      await _storage.write(key: 'token', value: _token);
      _user = User.fromJson(data['user']);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }
    } catch (_) {
      // ignore logout errors
    } finally {
      await _storage.delete(key: 'token');
      _token = null;
      _user = null;
      _error = null;
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
