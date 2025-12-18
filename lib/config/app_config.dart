import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get apiLoginEndpoint => dotenv.env['API_LOGIN_ENDPOINT'] ?? '/login';
  static String get apiRegisterEndpoint => dotenv.env['API_REGISTER_ENDPOINT'] ?? '/register';
  
  // JWT Configuration
  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';
  static String get jwtExpiration => dotenv.env['JWT_EXPIRATION'] ?? '3600';
  
  // Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  
  // Full URL helpers
  static String get loginUrl => '$apiBaseUrl$apiLoginEndpoint';
  static String get registerUrl => '$apiBaseUrl$apiRegisterEndpoint';
}
