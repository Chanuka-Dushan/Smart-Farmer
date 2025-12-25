import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  
  String get baseUrl => AppConfig.apiBaseUrl;

  // ==================== Authentication ====================

  /// Register a new user
  Future<AuthResponse> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? phoneNumber,
    String? address,
    String? fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'password': password,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (address != null) 'address': address,
          if (fcmToken != null) 'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_id', value: authResponse.user.id.toString());
        return authResponse;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_id', value: authResponse.user.id.toString());
        return authResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (response.statusCode == 403) {
        throw Exception('Your account has been banned');
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user (clear local storage)
  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_id');
  }

  // ==================== Profile Management ====================

  /// Get current user's profile
  Future<User> getProfile() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? firstname,
    String? lastname,
    String? phoneNumber,
    String? address,
    String? fcmToken,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final body = <String, dynamic>{};
      if (firstname != null) body['firstname'] = firstname;
      if (lastname != null) body['lastname'] = lastname;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (address != null) body['address'] = address;
      if (fcmToken != null) body['fcm_token'] = fcmToken;

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return User.fromJson(result['user']);
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/me/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        throw Exception('Incorrect old password');
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to change password: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user account (soft delete)
  Future<void> deleteAccount() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
        return;
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to delete account: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'auth_token');
    return token != null;
  }

  /// Get stored auth token
  Future<String?> getAuthToken() async {
    return await storage.read(key: 'auth_token');
  }
}
