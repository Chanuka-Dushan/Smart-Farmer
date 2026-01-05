import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Configuration
  static String get apiBaseUrl {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'https://farmerlk.me/backend';
    } catch (e) {
      return 'https://farmerlk.me/backend';
    }
  }
  
  // Legacy endpoints (deprecated - use ApiService instead)
  static String get apiLoginEndpoint => dotenv.env['API_LOGIN_ENDPOINT'] ?? '/login';
  static String get apiRegisterEndpoint => dotenv.env['API_REGISTER_ENDPOINT'] ?? '/register';
  
  // JWT Configuration
  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';
  static String get jwtExpiration => dotenv.env['JWT_EXPIRATION'] ?? '3600';
  
  // Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  
  // Legacy URL helpers (deprecated - use ApiService instead)
  static String get loginUrl => '$apiBaseUrl$apiLoginEndpoint';
  static String get registerUrl => '$apiBaseUrl$apiRegisterEndpoint';
  
  // New API endpoints
  static String get userRegisterUrl => '$apiBaseUrl/api/users/register';
  static String get userLoginUrl => '$apiBaseUrl/api/users/login';
  static String get userProfileUrl => '$apiBaseUrl/api/users/me';
  static String get userPasswordUrl => '$apiBaseUrl/api/users/me/password';
  
  // Stripe Configuration
  static String get stripePublishableKey {
    try {
      return dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_test_51SLiluIumKJBzyfFy3xnrCLzNWveG05qWlF2MboAkZmwUKe4LAro8cUKuXakXd2navyoCg6bKtmVaKkA8QdguJZI00Dn9lzOt2';
    } catch (e) {
      return 'pk_test_51SLiluIumKJBzyfFy3xnrCLzNWveG05qWlF2MboAkZmwUKe4LAro8cUKuXakXd2navyoCg6bKtmVaKkA8QdguJZI00Dn9lzOt2';
    }
  }
}
