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
  
  /// Convert relative image URLs to absolute URLs
  /// If the URL already has a host (http/https), return as-is
  /// If it's a relative path, prepend the base URL
  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    // If already a complete URL, return as-is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    // Remove 'file:///' prefix if present
    if (imageUrl.startsWith('file:///')) {
      imageUrl = imageUrl.substring(7); // Remove 'file:///'
    }
    
    // Remove leading slash if present (we'll add it back)
    final path = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    
    // Get base URL without trailing slash
    final base = apiBaseUrl.endsWith('/') 
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    
    return '$base$path';
  }
}
