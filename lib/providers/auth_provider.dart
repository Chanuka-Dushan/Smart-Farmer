import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
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
        _user = await _apiService.getProfile();
      } catch (e) {
        _isAuthenticated = false;
        _user = null;
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
    String? businessName,
    String? businessAddress,
    double? latitude,
    double? longitude,
    String? shopLocationName,
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
        businessName: businessName,
        businessAddress: businessAddress,
        latitude: latitude,
        longitude: longitude,
        shopLocationName: shopLocationName,
      );

      _user = authResponse.user is User ? authResponse.user : User.fromJson(authResponse.user);
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
      final authResponse = await _apiService.login(
        email: email,
        password: password,
      );

      _user = authResponse.user is User ? authResponse.user : User.fromJson(authResponse.user);
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

  /// Social login
  Future<bool> socialLogin({
    required String email,
    required String firstname,
    required String lastname,
    required String socialId,
    required String provider,
    String? profilePictureUrl,
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
      );

      _user = authResponse.user is User ? authResponse.user : User.fromJson(authResponse.user);
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
      _user = await _apiService.uploadProfilePicture(filePath);
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
      _user = await _apiService.deleteProfilePicture();
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

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
