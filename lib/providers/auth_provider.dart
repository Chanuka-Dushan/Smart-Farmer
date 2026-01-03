import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/seller_model.dart';
import '../services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  Seller? _seller;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Seller? get seller => _seller;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSeller => _seller != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _apiService.isAuthenticated();
    if (_isAuthenticated) {
      try {
        final userType = await _apiService.storage.read(key: 'user_type');
        if (userType == 'seller') {
          _seller = await _apiService.getSellerProfile().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );
          _user = null;
        } else {
          _user = await _apiService.getProfile().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );
          _seller = null;
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        _isAuthenticated = false;
        _user = null;
        _seller = null;
      }
    }
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? phoneNumber,
    String? address,
    String? userType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('FCM token not available: $e');
      }

      final authResponse = await _apiService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        address: address,
        fcmToken: fcmToken,
        userType: userType,
      );

      if (userType == 'seller') {
        _seller = authResponse.user is Seller ? authResponse.user : Seller.fromJson(authResponse.user);
        _user = null;
        await _apiService.storage.write(key: 'user_type', value: 'seller');
      } else {
        _user = authResponse.user is User ? authResponse.user : User.fromJson(authResponse.user);
        _seller = null;
        await _apiService.storage.write(key: 'user_type', value: 'buyer');
      }
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.login(email: email, password: password);
      
      // Handle dynamic user data
      dynamic userData = authResponse.user;
      Map<String, dynamic> userMap;
      
      if (userData is Map<String, dynamic>) {
        userMap = userData;
      } else if (userData is User) {
        userMap = (userData).toJson();
      } else if (userData is Seller) {
        userMap = (userData).toJson();
      } else {
        throw Exception('Invalid user data format');
      }
      
      final userType = userMap['user_type'] ?? 'buyer';

      if (userType == 'seller') {
        _seller = Seller.fromJson(userMap);
        _user = null;
        await _apiService.storage.write(key: 'user_type', value: 'seller');
      } else {
        _user = User.fromJson(userMap);
        _seller = null;
        await _apiService.storage.write(key: 'user_type', value: 'buyer');
      }
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Social login
  Future<bool> socialLogin({
    required String email,
    required String firstname,
    required String lastname,
    required String socialId,
    required String provider,
    String? profilePictureUrl,
    String? userType = 'buyer',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('FCM token not available: $e');
      }

      final authResponse = await _apiService.socialLogin(
        email: email,
        firstname: firstname,
        lastname: lastname,
        socialId: socialId,
        provider: provider,
        profilePictureUrl: profilePictureUrl,
        fcmToken: fcmToken,
        userType: userType,
      );

      final userData = authResponse.user as Map<String, dynamic>;
      final responseUserType = userData['user_type'] ?? 'buyer';

      if (responseUserType == 'seller') {
        _seller = Seller.fromJson(userData);
        _user = null;
        await _apiService.storage.write(key: 'user_type', value: 'seller');
      } else {
        _user = User.fromJson(userData);
        _seller = null;
        await _apiService.storage.write(key: 'user_type', value: 'buyer');
      }
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.resetPassword(token, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    _seller = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user profile
  Future<void> fetchProfile() async {
    try {
      _user = await _apiService.getProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstname,
    String? lastname,
    String? phoneNumber,
    String? address,
    String? profilePictureUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _apiService.updateProfile(
        firstname: firstname,
        lastname: lastname,
        phoneNumber: phoneNumber,
        address: address,
        profilePictureUrl: profilePictureUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile picture
  Future<bool> uploadProfilePicture(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isSeller) {
        _seller = await _apiService.uploadSellerLogo(filePath);
      } else {
        _user = await _apiService.uploadProfilePicture(filePath);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete profile picture
  Future<bool> deleteProfilePicture() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isSeller) {
        _seller = await _apiService.deleteSellerLogo();
      } else {
        _user = await _apiService.deleteProfilePicture();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteAccount();
      _user = null;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update seller profile
  Future<bool> updateSellerProfile({
    String? businessName,
    String? ownerFirstname,
    String? ownerLastname,
    String? phoneNumber,
    String? businessAddress,
    String? businessDescription,
    bool? onboardingCompleted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _seller = await _apiService.updateSellerProfile(
        businessName: businessName,
        ownerFirstname: ownerFirstname,
        ownerLastname: ownerLastname,
        phoneNumber: phoneNumber,
        businessAddress: businessAddress,
        businessDescription: businessDescription,
        onboarding_completed: onboardingCompleted,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Complete seller onboarding
  Future<bool> completeSellerOnboarding({
    required String businessName,
    required String businessAddress,
    required String latitude,
    required String longitude,
    String? logoPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _seller = await _apiService.completeSellerOnboarding(
        businessName: businessName,
        businessAddress: businessAddress,
        latitude: latitude,
        longitude: longitude,
        logoPath: logoPath,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
