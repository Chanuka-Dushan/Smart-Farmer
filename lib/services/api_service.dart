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
      print('🔐 Attempting login for: $email');
      print('🌐 API URL: $baseUrl/api/users/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_id', value: authResponse.user['id'].toString());
        final userType = authResponse.user['user_type'] ?? 'buyer';
        await storage.write(key: 'user_type', value: userType);
        print('✅ Login successful for user type: $userType');
        return authResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (response.statusCode == 403) {
        throw Exception('Your account has been banned');
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      rethrow;
    }
  }

  /// Social login (Google/Facebook)
  Future<AuthResponse> socialLogin({
    required String email,
    required String firstname,
    required String lastname,
    required String socialId,
    required String provider,
    String? profilePictureUrl,
    String? fcmToken,
    String? userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'firstname': firstname,
          'lastname': lastname,
          'social_id': socialId,
          'provider': provider,
          if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
          if (fcmToken != null) 'fcm_token': fcmToken,
          if (userType != null) 'user_type': userType,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_id', value: (authResponse.user as Map)['id'].toString());
        await storage.write(key: 'user_type', value: userType ?? 'buyer');
        return authResponse;
      } else {
        throw Exception('Social login failed: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Forgot password - request token
  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request password reset: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password with token
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user (clear local storage)
  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_type');
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
    String? profilePictureUrl,
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
      if (profilePictureUrl != null) body['profile_picture_url'] = profilePictureUrl;
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
        return User.fromJson(jsonDecode(response.body));
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

  /// Upload profile picture
  Future<User> uploadProfilePicture(String filePath) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/me/profile-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to upload profile picture: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete profile picture
  Future<User> deleteProfilePicture() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/me/profile-picture'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to delete profile picture: ${response.body}');
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

  /// Upload seller logo
  Future<Seller> uploadSellerLogo(String filePath) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not authenticated. Please login.');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/sellers/me/logo'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return Seller.fromJson(result);
      } else {
        throw Exception('Failed to upload logo: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete seller logo
  Future<Seller> deleteSellerLogo() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/sellers/me/logo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Seller.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to delete logo: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Complete seller onboarding
  Future<Seller> completeSellerOnboarding({
    required String businessName,
    required String businessAddress,
    required String latitude,
    required String longitude,
    String? logoPath,
  }) async {
    try {
      // 1. Update location and name
      final seller = await updateSellerProfile(
        businessName: businessName,
        businessAddress: businessAddress,
      );
      
      await updateSellerLocation(
        latitude: latitude,
        longitude: longitude,
      );

      // 2. Upload logo if provided
      if (logoPath != null) {
        await uploadSellerLogo(logoPath);
      }

      // 3. Mark as completed
      return await updateSellerProfile(onboarding_completed: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Update seller profile (corrected parameter name)
  Future<Seller> updateSellerProfile({
    String? businessName,
    String? ownerFirstname,
    String? ownerLastname,
    String? phoneNumber,
    String? businessAddress,
    String? businessDescription,
    String? fcmToken,
    bool? onboarding_completed,
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
      if (onboarding_completed != null) body['onboarding_completed'] = onboarding_completed;

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

  // ==================== Spare Parts ====================

  /// Create a new spare part request
  Future<Map<String, dynamic>> createSparePartRequest({
    required String title,
    required String description,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/api/spare-parts/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create request: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image for spare part request
  Future<Map<String, dynamic>> uploadSparePartImage(int requestId, String filePath) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/spare-parts/requests/$requestId/image'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get seller's spare part requests
  Future<List<dynamic>> getSparePartRequests() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/spare-parts/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load requests: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Submit an offer for a request
  Future<Map<String, dynamic>> submitSparePartOffer({
    required int requestId,
    required String price,
    required String description,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/api/spare-parts/requests/$requestId/offers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'price': price,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit offer: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's own requests
  Future<List<dynamic>> getMySparePartRequests() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/spare-parts/my-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load my requests: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get offers for a request
  Future<List<dynamic>> getOffersForRequest(int requestId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/spare-parts/requests/$requestId/offers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load offers: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update offer status
  Future<Map<String, dynamic>> updateOfferStatus(int offerId, String status) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/api/spare-parts/offers/$offerId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
