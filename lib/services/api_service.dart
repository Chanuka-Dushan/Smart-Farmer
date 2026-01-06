import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/seller_model.dart';
import '../models/shop_location_model.dart';
import '../utils/error_handler.dart';
import '../services/notification_service.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  
  String get baseUrl => AppConfig.apiBaseUrl;

  // ==================== Helper Methods ====================

  /// Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    
    if (includeAuth) {
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  /// Make HTTP request with comprehensive error handling
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    int timeoutSeconds = 30,
    bool skipLogoutOn401 = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      
      ErrorHandler.logInfo('Making $method request to: $endpoint');
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      ErrorHandler.logInfo('Response status: ${response.statusCode}');
      
      if (response.statusCode == 401 && !skipLogoutOn401) {
        // Token expired, logout user (but not for login/register endpoints)
        await logout();
        throw Exception('Session expired. Please login again.');
      }
      
      return response;
    } catch (e) {
      ErrorHandler.logError('API request failed for $method $endpoint', e);
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      throw Exception(friendlyMessage);
    }
  }

  /// Parse JSON response with error handling
  Map<String, dynamic> _parseJsonResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      ErrorHandler.logError('Failed to parse JSON response', e);
      throw Exception('Invalid response format from server');
    }
  }

  /// Generic POST request method
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _makeRequest('POST', endpoint, body: body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseJsonResponse(response);
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('POST request failed for $endpoint', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Generic GET request method
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _makeRequest('GET', endpoint);
      
      if (response.statusCode == 200) {
        return _parseJsonResponse(response);
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('GET request failed for $endpoint', e);
      throw Exception(friendlyMessage);
    }
  }

  // ==================== Authentication ====================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await storage.read(key: 'auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      ErrorHandler.logError('Failed to check authentication status', e);
      return false;
    }
  }

  /// Login user with email and password (checks both user and seller)
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      ErrorHandler.logInfo('Attempting unified login for email: $email');
      
      final response = await _makeRequest('POST', '/api/auth/unified-login',
          body: {
            'email': email,
            'password': password,
          },
          includeAuth: false,
          skipLogoutOn401: true); // Don't auto-logout on login failure

      if (response.statusCode == 200) {
        final jsonData = _parseJsonResponse(response);
        
        // Check user_type from the response
        final userType = jsonData['user']?['user_type'] ?? 'user';
        
        // Store authentication data
        await storage.write(key: 'auth_token', value: jsonData['access_token']);
        await storage.write(key: 'user_type', value: userType);
        await storage.write(key: '${userType}_id', value: jsonData['user']['id'].toString());
        
        ErrorHandler.logInfo('Unified login successful as $userType');
        
        // Return AuthResponse with proper type handling
        return AuthResponse.fromJson(jsonData);
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Unified login failed', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      ErrorHandler.logInfo('Attempting user registration for email: $email');

      // Get FCM token for registration
      final fcmToken = NotificationService.instance.currentToken;
      
      final response = await _makeRequest('POST', '/api/auth/register',
          body: {
            'email': email,
            'password': password,
            'firstname': firstname,
            'lastname': lastname,
            if (phoneNumber?.isNotEmpty == true) 'phone_number': phoneNumber,
            if (address?.isNotEmpty == true) 'address': address,
            if (fcmToken?.isNotEmpty == true) 'fcm_token': fcmToken,
          },
          includeAuth: false,
          skipLogoutOn401: true); // Don't auto-logout on registration failure

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(_parseJsonResponse(response));
        
        // Store authentication data
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_type', value: 'user');
        await storage.write(key: 'user_id', value: authResponse.user.id.toString());
        
        ErrorHandler.logInfo('User registration successful');
        return authResponse;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('User registration failed', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Register new seller
  Future<AuthResponse> registerSeller({
    required String email,
    required String password,
    required String businessName,
    required String ownerFirstname,
    required String ownerLastname,
    String? phoneNumber,
    String? businessAddress,
    String? businessDescription,
    String? latitude,
    String? longitude,
    String? shopLocationName,
  }) async {
    try {
      ErrorHandler.logInfo('Attempting seller registration for email: $email');

      // Get FCM token for registration
      final fcmToken = NotificationService.instance.currentToken;

      final body = {
        'email': email,
        'password': password,
        'business_name': businessName,
        'owner_firstname': ownerFirstname,
        'owner_lastname': ownerLastname,
      };

      // Add optional fields if provided
      if (phoneNumber?.isNotEmpty == true) body['phone_number'] = phoneNumber!;
      if (businessAddress?.isNotEmpty == true) body['business_address'] = businessAddress!;
      if (businessDescription?.isNotEmpty == true) body['business_description'] = businessDescription!;
      if (latitude?.isNotEmpty == true) body['latitude'] = latitude!;
      if (longitude?.isNotEmpty == true) body['longitude'] = longitude!;
      if (shopLocationName?.isNotEmpty == true) body['shop_location_name'] = shopLocationName!;
      if (fcmToken?.isNotEmpty == true) body['fcm_token'] = fcmToken!;

      final response = await _makeRequest('POST', '/api/sellers/register',
          body: body, 
          includeAuth: false,
          skipLogoutOn401: true); // Don't auto-logout on registration failure

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(_parseJsonResponse(response));
        
        // Store authentication data
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_type', value: 'seller');
        // Access id from the dynamic user object (could be Map or Seller)
        final sellerId = authResponse.user is Map 
            ? authResponse.user['id'].toString() 
            : authResponse.user.id.toString();
        await storage.write(key: 'seller_id', value: sellerId);
        
        ErrorHandler.logInfo('Seller registration successful');
        return authResponse;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Seller registration failed', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Login seller
  Future<AuthResponse> loginSeller({
    required String email,
    required String password,
  }) async {
    try {
      ErrorHandler.logInfo('Attempting seller login for email: $email');

      final response = await _makeRequest('POST', '/api/sellers/login',
          body: {
            'email': email,
            'password': password,
          },
          includeAuth: false,
          skipLogoutOn401: true); // Don't auto-logout on login failure

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(_parseJsonResponse(response));
        
        // Store authentication data
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_type', value: 'seller');
        // Access id from the dynamic user object (could be Map or Seller)
        final sellerId = authResponse.user is Map 
            ? authResponse.user['id'].toString() 
            : authResponse.user.id.toString();
        await storage.write(key: 'seller_id', value: sellerId);
        
        ErrorHandler.logInfo('Seller login successful');
        return authResponse;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Seller login failed', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      ErrorHandler.logInfo('Logging out user');
      
      // Clear stored data
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_type');
      await storage.delete(key: 'user_id');
      await storage.delete(key: 'seller_id');
      
      // Clear FCM token from server if possible
      try {
        await _makeRequest('POST', '/api/auth/logout');
      } catch (e) {
        // Ignore logout API errors as local logout is more important
        ErrorHandler.logWarning('Failed to logout on server: $e');
      }
      
      ErrorHandler.logInfo('User logged out successfully');
    } catch (e) {
      ErrorHandler.logError('Logout failed', e);
      // Continue with local logout even if server logout fails
    }
  }

  /// Social login (Google/Facebook)
  Future<AuthResponse> socialLogin({
    required String provider,
    required String email,
    required String firstname,
    required String lastname,
    required String socialId,
    String? photoUrl,
  }) async {
    try {
      ErrorHandler.logInfo('Attempting social login for email: $email');

      // Get FCM token for registration
      final fcmToken = NotificationService.instance.currentToken;
      
      final response = await _makeRequest('POST', '/api/auth/social',
          body: {
            'email': email,
            'firstname': firstname,
            'lastname': lastname,
            'social_id': socialId,
            'provider': provider,
            if (photoUrl?.isNotEmpty == true) 'profile_picture_url': photoUrl,
            if (fcmToken?.isNotEmpty == true) 'fcm_token': fcmToken,
          },
          includeAuth: false);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(_parseJsonResponse(response));
        
        // Store authentication data
        await storage.write(key: 'auth_token', value: authResponse.accessToken);
        await storage.write(key: 'user_type', value: 'user');
        
        // Handle different user types for storing user_id
        String userId;
        if (authResponse.user is Map<String, dynamic>) {
          final userData = authResponse.user as Map<String, dynamic>;
          userId = (userData['id'] ?? 0).toString();
        } else {
          userId = authResponse.user.id.toString();
        }
        await storage.write(key: 'user_id', value: userId);
        
        ErrorHandler.logInfo('Social login successful');
        return authResponse;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Social login failed', e);
      throw Exception(friendlyMessage);
    }
  }

  // ==================== User Profile Management ====================

  /// Get current user's profile
  Future<User> getProfile() async {
    try {
      final response = await _makeRequest('GET', '/api/users/me');

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final user = User.fromJson(result);
        ErrorHandler.logInfo('User profile loaded successfully');
        return user;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load profile', e);
      throw Exception(friendlyMessage);
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
      // Get current FCM token if not provided
      fcmToken ??= NotificationService.instance.currentToken;
      
      final body = <String, dynamic>{};
      if (firstname?.isNotEmpty == true) body['firstname'] = firstname;
      if (lastname?.isNotEmpty == true) body['lastname'] = lastname;
      if (phoneNumber?.isNotEmpty == true) body['phone_number'] = phoneNumber;
      if (address?.isNotEmpty == true) body['address'] = address;
      if (fcmToken?.isNotEmpty == true) body['fcm_token'] = fcmToken;

      final response = await _makeRequest('PUT', '/api/users/me', body: body);

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final user = User.fromJson(result['user']);
        ErrorHandler.logInfo('Profile updated successfully');
        return user;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to update profile', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Change user password with comprehensive error handling
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final body = {
        'old_password': oldPassword,
        'new_password': newPassword,
      };

      final response = await _makeRequest('PUT', '/api/users/me/password', body: body);

      if (response.statusCode == 200) {
        ErrorHandler.logInfo('Password changed successfully');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to change password', e);
      throw Exception(friendlyMessage);
    }
  }

  // ==================== Seller Profile Management ====================

  /// Get current seller's profile
  Future<Seller> getSellerProfile() async {
    try {
      final response = await _makeRequest('GET', '/api/sellers/me');

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final seller = Seller.fromJson(result);
        ErrorHandler.logInfo('Seller profile loaded successfully');
        return seller;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load seller profile', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get seller profile by ID
  Future<Map<String, dynamic>> getSellerById(int sellerId) async {
    try {
      final response = await _makeRequest('GET', '/api/sellers/$sellerId');

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        ErrorHandler.logInfo('Seller details loaded successfully for seller $sellerId');
        return result;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load seller details for seller $sellerId', e);
      throw Exception(friendlyMessage);
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
      fcmToken ??= NotificationService.instance.currentToken;
      
      final body = <String, dynamic>{};
      if (businessName != null) body['business_name'] = businessName;
      if (ownerFirstname != null) body['owner_firstname'] = ownerFirstname;
      if (ownerLastname != null) body['owner_lastname'] = ownerLastname;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (businessAddress != null) body['business_address'] = businessAddress;
      if (businessDescription != null) body['business_description'] = businessDescription;
      if (fcmToken != null) body['fcm_token'] = fcmToken;

      final response = await _makeRequest('PUT', '/api/sellers/me', body: body);

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final seller = Seller.fromJson(result);
        ErrorHandler.logInfo('Seller profile updated successfully');
        return seller;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to update seller profile', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Change seller password
  Future<void> changeSellerPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final body = {
        'old_password': oldPassword,
        'new_password': newPassword,
      };

      final response = await _makeRequest('PUT', '/api/sellers/me/password', body: body);

      if (response.statusCode == 200) {
        ErrorHandler.logInfo('Seller password changed successfully');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to change seller password', e);
      throw Exception(friendlyMessage);
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
      final body = {
        'latitude': latitude,
        'longitude': longitude,
      };
      if (shopLocationName != null) {
        body['shop_location_name'] = shopLocationName;
      }

      final response = await _makeRequest('PUT', '/api/sellers/me/location', body: body);

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final seller = Seller.fromJson(result);
        ErrorHandler.logInfo('Seller location updated successfully');
        return seller;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to update seller location', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get all shop locations for map display
  Future<List<ShopLocation>> getShopLocations() async {
    try {
      final response = await _makeRequest('GET', '/api/sellers/locations', includeAuth: false);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final locations = data.map((json) => ShopLocation.fromJson(json)).toList();
        ErrorHandler.logInfo('Shop locations loaded successfully');
        return locations;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load shop locations', e);
      throw Exception(friendlyMessage);
    }
  }

  // ==================== Spare Parts Offers Management ====================

  /// Get offers for a specific spare part request
  Future<List<dynamic>> getOffersForRequest(int requestId) async {
    try {
      final response = await _makeRequest('GET', '/api/spare-parts/requests/$requestId/offers');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        ErrorHandler.logInfo('Offers loaded successfully for request $requestId');
        return data;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load offers for request $requestId', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Update offer status (accept, reject, etc.)
  Future<void> updateOfferStatus(int offerId, String status) async {
    try {
      final body = {'status': status};
      final response = await _makeRequest('PUT', '/api/spare-parts/offers/$offerId/status', body: body);

      if (response.statusCode == 200) {
        ErrorHandler.logInfo('Offer $offerId status updated to $status');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to update offer status', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get spare part requests for sellers
  Future<List<dynamic>> getSparePartRequests() async {
    try {
      final response = await _makeRequest('GET', '/api/spare-parts/requests');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        ErrorHandler.logInfo('Spare part requests loaded successfully');
        return data;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load spare part requests', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get user's own spare part requests
  Future<List<dynamic>> getMySparePartRequests() async {
    try {
      final response = await _makeRequest('GET', '/api/spare-parts/my-requests');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        ErrorHandler.logInfo('My spare part requests loaded successfully');
        return data;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load my spare part requests', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Create a new spare part request
  Future<dynamic> createSparePartRequest({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'category': category,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final response = await _makeRequest('POST', '/api/spare-parts/requests', body: body);

      if (response.statusCode == 201) {
        final result = _parseJsonResponse(response);
        ErrorHandler.logInfo('Spare part request created successfully');
        return result;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to create spare part request', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Submit an offer for a spare part request
  Future<void> submitSparePartOffer({
    required int requestId,
    required double price,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'price': price,
        'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final response = await _makeRequest('POST', '/api/spare-parts/requests/$requestId/offers', body: body);

      if (response.statusCode == 201) {
        ErrorHandler.logInfo('Spare part offer submitted successfully');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to submit spare part offer', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get seller's offers
  Future<List<dynamic>> getMyOffers() async {
    try {
      final response = await _makeRequest('GET', '/api/spare-parts/my-offers');

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        ErrorHandler.logInfo('Fetched seller offers successfully');
        return result is List ? List<dynamic>.from(result as List) : [];
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to fetch seller offers', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(String imagePath) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload/profile-picture');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication header
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final imageUrl = result['url'] ?? result['image_url'] ?? result['profile_picture_url'];
        ErrorHandler.logInfo('Profile picture uploaded successfully');
        return imageUrl;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to upload profile picture', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Predict spare part lifecycle using AI and vision analysis
  Future<Map<String, dynamic>> predictLifecycle({
    required String partName,
    double? usageHours,
    required String location,
    required String imagePath,
  }) async {
    try {
      print('🔧 Starting lifecycle prediction API call...');
      print('📝 Part: $partName, Hours: ${usageHours ?? 'N/A'}, Location: $location');
      print('📸 Image path: $imagePath');

      final uri = Uri.parse('$baseUrl/api/predict-lifecycle');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('🔑 Auth token added');
      } else {
        print('⚠️ No auth token found');
      }

      // Add form fields
      request.fields['part_name'] = partName;
      if (usageHours != null) {
        request.fields['usage_hours'] = usageHours.toString();
      }
      request.fields['location'] = location;
      print('📋 Form fields added');

      // Check if image file exists
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: $imagePath');
      }
      print('📁 Image file exists, size: ${imageFile.lengthSync()} bytes');

      // Add image file
      final multipartFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(multipartFile);
      print('🖼️ Image file added to request');

      // Send request
      print('📤 Sending request to $uri...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response received: ${response.statusCode}');
      print('📄 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        print('✅ Prediction completed successfully');
        ErrorHandler.logInfo('Lifecycle prediction completed successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('💥 API call failed: $e');
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to predict lifecycle', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Upload spare part image for request
  Future<String> uploadSparePartImage(String imagePath) async {
    try {
      print('📸 Uploading spare part image...');
      print('📁 Image path: $imagePath');

      final uri = Uri.parse('$baseUrl/api/spare-parts/upload-image');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Check if image file exists
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: $imagePath');
      }

      // Add image file with explicit content type
      String contentType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imagePath.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (imagePath.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }
      
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);
      print('🖼️ Image file added to request with content type: $contentType');

      // Send request
      print('📤 Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        final imageUrl = result['image_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('No image URL returned from server');
        }
        print('✅ Image uploaded successfully: $imageUrl');
        ErrorHandler.logInfo('Spare part image uploaded successfully');
        return imageUrl;
      } else {
        print('❌ Upload Error: ${response.statusCode} - ${response.body}');
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('💥 Image upload failed: $e');
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to upload spare part image', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final response = await _makeRequest('DELETE', '/api/users/me');

      if (response.statusCode == 200) {
        await logout();
        ErrorHandler.logInfo('Account deleted successfully');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to delete account', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Create payment intent for spare part order
  Future<Map<String, dynamic>> createPaymentIntent(
    int offerId, {
    bool saveCard = false,
    String? paymentMethodId,
  }) async {
    try {
      final body = {
        'offer_id': offerId,
        'save_card': saveCard,
      };
      if (paymentMethodId != null) {
        body['payment_method_id'] = paymentMethodId;
      }
      
      final response = await _makeRequest(
        'POST',
        '/api/payments/create-intent',
        body: body,
      );

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        ErrorHandler.logInfo('Payment intent created successfully');
        return result;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to create payment intent', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Confirm payment
  /// Returns a map with 'success' (bool) and optionally 'status' and 'message' fields
  /// If success is false, check 'status' to see if payment is still in progress
  Future<Map<String, dynamic>> confirmPayment(
    String paymentIntentId, {
    bool saveCard = false,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/api/payments/confirm',
        body: {
          'payment_intent_id': paymentIntentId,
          'save_card': saveCard,
        },
      );

      if (response.statusCode == 200) {
        final result = _parseJsonResponse(response);
        // Backend now returns success: true/false and status field
        // Handle both old format (success: true) and new format (success: false with status)
        if (result['success'] == true) {
          ErrorHandler.logInfo('Payment confirmed successfully');
        } else {
          final status = result['status'] as String?;
          final message = result['message'] as String?;
          ErrorHandler.logInfo('Payment confirmation response: status=$status, message=$message');
        }
        return result;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to confirm payment', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get user's payments
  Future<List<dynamic>> getMyPayments() async {
    try {
      final response = await _makeRequest('GET', '/api/payments/my-payments');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        ErrorHandler.logInfo('My payments loaded successfully');
        return data;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load my payments', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get seller's approved payments
  Future<List<dynamic>> getSellerPayments() async {
    try {
      final response = await _makeRequest('GET', '/api/payments/seller-payments');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        ErrorHandler.logInfo('Seller payments loaded successfully');
        return data;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load seller payments', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Get saved payment methods
  Future<List<dynamic>> getSavedPaymentMethods() async {
    try {
      final response = await _makeRequest('GET', '/api/payments/saved-methods');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        ErrorHandler.logInfo('Saved payment methods loaded successfully');
        return data;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to load saved payment methods', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Delete saved payment method
  Future<void> deleteSavedPaymentMethod(int methodId) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/api/payments/saved-methods/$methodId',
      );

      if (response.statusCode == 200) {
        ErrorHandler.logInfo('Payment method deleted successfully');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to delete payment method', e);
      throw Exception(friendlyMessage);
    }
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(int methodId) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '/api/payments/saved-methods/$methodId/set-default',
      );

      if (response.statusCode == 200) {
        ErrorHandler.logInfo('Default payment method updated successfully');
        return;
      } else {
        final errorMessage = ErrorHandler.handleHttpError(response);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final friendlyMessage = ErrorHandler.getUserFriendlyMessage(e);
      ErrorHandler.logError('Failed to set default payment method', e);
      throw Exception(friendlyMessage);
    }
  }
}