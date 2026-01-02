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
  String? _userType; // 'user' or 'seller'

  User? get user => _user;
  Seller? get seller => _seller;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSeller => _userType == 'seller';

  AuthProvider() {
    checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _apiService.isAuthenticated();
    if (_isAuthenticated) {
      try {
        // Try to get seller profile first
        try {
          _seller = await _apiService.getSellerProfile();
          _userType = 'seller';
        } catch (e) {
          // If seller profile fails, try user profile
          try {
            _user = await _apiService.getProfile();
            _userType = 'user';
          } catch (e) {
            _isAuthenticated = false;
          }
        }
      } catch (e) {
        _isAuthenticated = false;
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        address: address,
      );

      _user = authResponse.user;
      _userType = 'user';
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

  /// Register new seller
  Future<bool> registerSeller({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.registerSeller(
        email: email,
        password: password,
        businessName: businessName,
        ownerFirstname: ownerFirstname,
        ownerLastname: ownerLastname,
        phoneNumber: phoneNumber,
        businessAddress: businessAddress,
        businessDescription: businessDescription,
        latitude: latitude,
        longitude: longitude,
        shopLocationName: shopLocationName,
      );

      _seller = authResponse.user;
      _userType = 'seller';
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

      _user = authResponse.user;
      _userType = 'user';
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

  /// Login seller
  Future<bool> loginSeller({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.loginSeller(
        email: email,
        password: password,
      );

      _seller = authResponse.user;
      _userType = 'seller';
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

  /// Social login (Google/Facebook)
  Future<bool> socialLogin({
    required String provider, // 'google' or 'facebook'
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // For now, create a temporary implementation
      // This would normally call a social login API endpoint
      if (email != null && name != null) {
        // Simulate successful login with social provider data
        final nameParts = name.split(' ');
        final firstname = nameParts.isNotEmpty ? nameParts.first : 'User';
        final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        // Try to register/login with social data
        final authResponse = await _apiService.register(
          firstname: firstname,
          lastname: lastname,
          email: email,
          password: 'social_${provider}_${idToken.substring(0, 8)}', // Temporary password
        );

        _user = authResponse.user;
        _userType = 'user';
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      throw Exception('Invalid social login data');
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
    _userType = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user profile
  Future<void> fetchProfile() async {
    try {
      if (isSeller) {
        _seller = await _apiService.getSellerProfile();
      } else {
        _user = await _apiService.getProfile();
      }
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

  /// Update seller profile
  Future<bool> updateSellerProfile({
    String? businessName,
    String? ownerFirstname,
    String? ownerLastname,
    String? phoneNumber,
    String? businessAddress,
    String? businessDescription,
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
    String? businessDescription,
    String? latitude,
    String? longitude,
    String? shopLocationName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _seller = await _apiService.updateSellerProfile(
        businessDescription: businessDescription,
      );
      
      if (latitude != null && longitude != null) {
        _seller = await _apiService.updateSellerLocation(
          latitude: latitude,
          longitude: longitude,
          shopLocationName: shopLocationName,
        );
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
      if (isSeller) {
        await _apiService.changeSellerPassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      } else {
        await _apiService.changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
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

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // This would normally call a forgot password API endpoint
      // For now, return success as placeholder
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
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

  /// Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // This would normally call a reset password API endpoint
      // For now, return success as placeholder
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
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
  Future<bool> uploadProfilePicture(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // This would normally upload the image to server
      // For now, return success as placeholder
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
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
      // This would normally delete the profile picture from server
      // For now, return success as placeholder
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
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
      _seller = null;
      _userType = null;
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
