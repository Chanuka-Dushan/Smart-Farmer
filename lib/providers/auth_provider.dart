import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/seller_model.dart';
import '../services/api_service.dart';

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
  ApiService get apiService => _apiService;

  AuthProvider() {
    checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _apiService.isAuthenticated();
    if (_isAuthenticated) {
      try {
        // Read the stored user_type from storage
        final storage = const FlutterSecureStorage();
        final storedUserType = await storage.read(key: 'user_type');
        
        if (storedUserType == 'seller') {
          _seller = await _apiService.getSellerProfile();
          _userType = 'seller';
        } else {
          _user = await _apiService.getProfile();
          _userType = 'user';
        }
      } catch (e) {
        _isAuthenticated = false;
      }
    }
    notifyListeners();
  }
  
  /// Clear image cache for profile pictures
  void _clearProfileImageCache() {
    try {
      final userPicUrl = _user?.profilePictureUrl;
      if (userPicUrl != null && userPicUrl.isNotEmpty) {
        try {
          final imageProvider = NetworkImage(userPicUrl);
          imageProvider.evict();
        } catch (e) {
          // If eviction fails, continue to clear entire cache
        }
      }
      final sellerLogoUrl = _seller?.logoUrl;
      if (sellerLogoUrl != null && sellerLogoUrl.isNotEmpty) {
        try {
          final imageProvider = NetworkImage(sellerLogoUrl);
          imageProvider.evict();
        } catch (e) {
          // If eviction fails, continue to clear entire cache
        }
      }
      // Clear entire image cache to ensure profile pictures are refreshed
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      // Ignore cache clearing errors
      print('Warning: Failed to clear image cache: $e');
    }
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

      _seller = authResponse.user is Seller 
          ? authResponse.user 
          : Seller.fromJson(authResponse.user);
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

  /// Login user (checks both regular user and seller)
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

      // Check if the response contains seller data or user data
      if (authResponse.user is Map<String, dynamic>) {
        final userData = authResponse.user as Map<String, dynamic>;
        
        // Check if it's a seller by looking for business_name
        if (userData.containsKey('business_name')) {
          _seller = Seller.fromJson(userData);
          _userType = 'seller';
          _user = null;
        } else {
          _user = User.fromJson(userData);
          _userType = 'user';
          _seller = null;
        }
      } else if (authResponse.user is Seller) {
        _seller = authResponse.user;
        _userType = 'seller';
        _user = null;
      } else if (authResponse.user is User) {
        _user = authResponse.user;
        _userType = 'user';
        _seller = null;
      }
      
      _isAuthenticated = true;
      _isLoading = false;
      
      // Refresh profile to get latest data including profile picture
      try {
        if (_userType == 'user') {
          _user = await _apiService.getProfile();
        } else if (_userType == 'seller') {
          _seller = await _apiService.getSellerProfile();
        }
      } catch (e) {
        // If refresh fails, continue with existing data
        print('Warning: Failed to refresh profile after login: $e');
      }
      
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

      _seller = authResponse.user is Seller 
          ? authResponse.user 
          : Seller.fromJson(authResponse.user);
      _userType = 'seller';
      _isAuthenticated = true;
      _isLoading = false;
      
      // Refresh profile to get latest data including logo
      try {
        _seller = await _apiService.getSellerProfile();
      } catch (e) {
        // If refresh fails, continue with existing data
        print('Warning: Failed to refresh seller profile after login: $e');
      }
      
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
    String? userType, // 'user' or 'seller'
    String? businessName, // For seller registration
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email != null && name != null) {
        // Parse name into firstname and lastname
        final nameParts = name.split(' ');
        final firstname = nameParts.isNotEmpty ? nameParts.first : 'User';
        final lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        // Determine if registering as seller
        final isSeller = userType == 'seller';
        
        if (isSeller) {
          // Register as seller using social login
          final sellerResponse = await _apiService.registerSeller(
            email: email,
            password: 'social_${provider}_${idToken.substring(0, 8)}', // Temporary password
            businessName: businessName ?? '$firstname\'s Shop',
            ownerFirstname: firstname,
            ownerLastname: lastname,
            phoneNumber: null,
          );
          _seller = sellerResponse.user is Seller 
              ? sellerResponse.user 
              : Seller.fromJson(sellerResponse.user);
          _userType = 'seller';
        } else {
          // Call the dedicated social login endpoint for regular users
          final authResponse = await _apiService.socialLogin(
            provider: provider,
            email: email,
            firstname: firstname,
            lastname: lastname,
            socialId: idToken,
            photoUrl: photoUrl,
          );
          
          // Check if the response contains seller data or user data
          if (authResponse.user is Map<String, dynamic>) {
            final userData = authResponse.user as Map<String, dynamic>;
            
            // Check if it's a seller by looking for business_name
            if (userData.containsKey('business_name')) {
              _seller = Seller.fromJson(userData);
              _userType = 'seller';
              _user = null;
            } else {
              _user = User.fromJson(userData);
              _userType = 'user';
              _seller = null;
            }
          } else if (authResponse.user is Seller) {
            _seller = authResponse.user;
            _userType = 'seller';
            _user = null;
          } else if (authResponse.user is User) {
            _user = authResponse.user;
            _userType = 'user';
            _seller = null;
          }
        }

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
    // Clear image cache before logout
    _clearProfileImageCache();
    
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

  /// Update seller location
  Future<bool> updateSellerLocation({
    required String latitude,
    required String longitude,
    String? shopLocationName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _seller = await _apiService.updateSellerLocation(
        latitude: latitude,
        longitude: longitude,
        shopLocationName: shopLocationName,
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
    String? businessName,
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
      // Update seller profile with business info
      _seller = await _apiService.updateSellerProfile(
        businessName: businessName,
        businessAddress: businessAddress,
        businessDescription: businessDescription,
      );
      
      // Update location if provided
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
      // Upload image to server and get URL
      final imageUrl = await _apiService.uploadProfilePicture(imagePath);
      
      // Update the profile picture URL immediately
      if (_userType == 'user' && _user != null) {
        // Create updated user with new profile picture URL
        _user = User(
          id: _user!.id,
          firstname: _user!.firstname,
          lastname: _user!.lastname,
          email: _user!.email,
          phoneNumber: _user!.phoneNumber,
          address: _user!.address,
          profilePictureUrl: imageUrl,
          isSocialLogin: _user!.isSocialLogin,
          isBanned: _user!.isBanned,
          isDeleted: _user!.isDeleted,
          createdAt: _user!.createdAt,
          updatedAt: DateTime.now(),
        );
      } else if (_userType == 'seller' && _seller != null) {
        // Create updated seller with new logo URL
        _seller = Seller(
          id: _seller!.id,
          businessName: _seller!.businessName,
          ownerFirstname: _seller!.ownerFirstname,
          ownerLastname: _seller!.ownerLastname,
          email: _seller!.email,
          phoneNumber: _seller!.phoneNumber,
          businessAddress: _seller!.businessAddress,
          businessDescription: _seller!.businessDescription,
          logoUrl: imageUrl,
          latitude: _seller!.latitude,
          longitude: _seller!.longitude,
          shopLocationName: _seller!.shopLocationName,
          isVerified: _seller!.isVerified,
          isActive: _seller!.isActive,
          onboardingCompleted: _seller!.onboardingCompleted,
          createdAt: _seller!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      
      // Notify listeners immediately to update UI
      _isLoading = false;
      notifyListeners();
      
      // Then refresh profile from server in background to ensure sync
      try {
        if (_userType == 'user') {
          _user = await _apiService.getProfile();
        } else if (_userType == 'seller') {
          _seller = await _apiService.getSellerProfile();
        }
        // Notify again after server refresh
        notifyListeners();
      } catch (e) {
        // If background refresh fails, continue with local update
        print('Warning: Failed to refresh profile after upload: $e');
      }
      
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
