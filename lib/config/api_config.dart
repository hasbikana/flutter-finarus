class ApiConfig {
  static const String baseUrl = 'http://192.168.18.15:8001/api';
  // Laragon: http://localhost/finarus/public/api
  // Production: https://your-domain.com/api

  static const Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Google OAuth web client ID (from Google Cloud Console)
  static const String googleWebClientId =
      '21594976412-s99hc0i7c38f1npkmep65e12lantfjhv.apps.googleusercontent.com';
}
