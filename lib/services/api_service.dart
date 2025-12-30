import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/seller_model.dart';
import '../models/shop_location_model.dart';

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
    String? userType,
    String? businessName,
    String? businessAddress,
    double? latitude,
    double? longitude,
    String? shopLocationName,
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
          if (userType != null) 'user_type': userType,
          if (businessName != null) 'business_name': businessName,
          if (businessAddress != null) 'business_address': businessAddress,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (shopLocationName != null) 'shop_location_name': shopLocationName,
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

  // ==================== Seller Authentication ====================

  /// Register a new seller
  Future<AuthResponse> registerSeller({
    required String businessName,
    required String ownerFirstname,
    required String ownerLastname,
    required String email,
    required String password,
    String? phoneNumber,
    String? businessAddress,
    String? businessDescription,
    String? fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_name': businessName,
          'owner_firstname': ownerFirstname,
          'owner_lastname': ownerLastname,
          'email': email,
          'password': password,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (businessAddress != null) 'business_address': businessAddress,
          if (businessDescription != null) 'business_description': businessDescription,
          if (fcmToken != null) 'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_type', value: 'seller');
        await storage.write(key: 'seller_id', value: authResponse.user.id.toString());
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

  /// Login seller
  Future<AuthResponse> loginSeller({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_type', value: 'seller');
        await storage.write(key: 'seller_id', value: authResponse.user.id.toString());
        return authResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Seller Profile Management ====================

  /// Get current seller's profile
  Future<Seller> getSellerProfile() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/sellers/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Seller.fromJson(jsonDecode(response.body));
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

  /// Update seller profile
  Future<Seller> updateSellerProfile({
    String? businessName,
    String? ownerFirstname,
    String? ownerLastname,
    String? phoneNumber,
    String? businessAddress,
    String? businessDescription,
    String? fcmToken,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final body = <String, dynamic>{};
      if (businessName != null) body['business_name'] = businessName;
      if (ownerFirstname != null) body['owner_firstname'] = ownerFirstname;
      if (ownerLastname != null) body['owner_lastname'] = ownerLastname;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (businessAddress != null) body['business_address'] = businessAddress;
      if (businessDescription != null) body['business_description'] = businessDescription;
      if (fcmToken != null) body['fcm_token'] = fcmToken;

      final response = await http.put(
        Uri.parse('$baseUrl/api/sellers/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return Seller.fromJson(result);
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

  /// Change seller password
  Future<void> changeSellerPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/sellers/me/password'),
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

  // ==================== Shop Location Management ====================

  /// Update seller's shop location
  Future<Seller> updateSellerLocation({
    required String latitude,
    required String longitude,
    String? shopLocationName,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final body = {
        'latitude': latitude,
        'longitude': longitude,
      };
      if (shopLocationName != null) {
        body['shop_location_name'] = shopLocationName;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/sellers/me/location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return Seller.fromJson(result);
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all shop locations for map display
  Future<List<ShopLocation>> getShopLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sellers/locations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ShopLocation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shop locations: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
