import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

/// Centralized error handling utility for Smart Farmer app
/// 
/// This class provides comprehensive error handling, logging, and user feedback
class ErrorHandler {
  static const String _logTag = 'SmartFarmer';
  
  /// Log error with context information
  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔥 [$_logTag ERROR] $message');
      debugPrint('🔥 Error: $error');
      if (stackTrace != null) {
        debugPrint('🔥 Stack trace: $stackTrace');
      }
    }
    
    // TODO: Send error to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // _sendErrorReport(message, error, stackTrace);
  }

  /// Log warning with context information
  static void logWarning(String message, [dynamic details]) {
    if (kDebugMode) {
      debugPrint('⚠️ [$_logTag WARNING] $message');
      if (details != null) {
        debugPrint('⚠️ Details: $details');
      }
    }
  }

  /// Log info message
  static void logInfo(String message, [dynamic details]) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$_logTag INFO] $message');
      if (details != null) {
        debugPrint('ℹ️ Details: $details');
      }
    }
  }

  /// Handle HTTP response errors
  static String handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return _parseErrorMessage(response.body) ?? 'Bad request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found. Please try again.';
      case 409:
        return 'Data conflict. This resource may already exist.';
      case 422:
        return _parseErrorMessage(response.body) ?? 'Invalid data provided.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Request timeout. Please check your connection and try again.';
      default:
        return 'Unexpected error occurred (${response.statusCode}). Please try again.';
    }
  }

  /// Handle network connectivity errors
  static String handleNetworkError(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (error is HttpException) {
      return 'Connection failed. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid data format received from server.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timeout. Please check your connection and try again.';
    } else {
      return 'Network error occurred. Please check your connection and try again.';
    }
  }

  /// Handle authentication errors
  static String handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (errorString.contains('email already registered')) {
      return 'This email is already registered. Try logging in instead.';
    } else if (errorString.contains('user not found')) {
      return 'Account not found. Please check your email or register a new account.';
    } else if (errorString.contains('account has been banned')) {
      return 'Your account has been suspended. Please contact support.';
    } else if (errorString.contains('not authenticated')) {
      return 'Please login to continue.';
    } else if (errorString.contains('session expired')) {
      return 'Your session has expired. Please login again.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  /// Handle file operation errors
  static String handleFileError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please grant necessary permissions.';
    } else if (errorString.contains('file not found')) {
      return 'File not found. Please select a valid file.';
    } else if (errorString.contains('storage')) {
      return 'Storage error. Please free up some space and try again.';
    } else if (errorString.contains('format')) {
      return 'Invalid file format. Please select a supported file type.';
    } else {
      return 'File operation failed. Please try again.';
    }
  }

  /// Handle camera/permission errors
  static String handlePermissionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('camera')) {
      return 'Camera permission required. Please grant camera access in settings.';
    } else if (errorString.contains('location')) {
      return 'Location permission required. Please grant location access in settings.';
    } else if (errorString.contains('storage')) {
      return 'Storage permission required. Please grant storage access in settings.';
    } else if (errorString.contains('notification')) {
      return 'Notification permission required. Please enable notifications in settings.';
    } else {
      return 'Permission required. Please grant necessary permissions in settings.';
    }
  }

  /// Handle form validation errors
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  /// Validate name fields
  static String? validateName(String? name, [String fieldName = 'Name']) {
    if (name == null || name.isEmpty) {
      return '$fieldName is required';
    }
    
    if (name.length < 2) {
      return '$fieldName must be at least 2 characters long';
    }
    
    if (name.length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Optional field
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Parse error message from API response
  static String? _parseErrorMessage(String responseBody) {
    try {
      final Map<String, dynamic> errorData = 
          responseBody.isNotEmpty ? 
          (responseBody.startsWith('{') ? 
           _parseJson(responseBody) : 
           {'detail': responseBody}) : 
          {};
      
      return errorData['detail'] ?? 
             errorData['message'] ?? 
             errorData['error'] ??
             (errorData['errors']?.isNotEmpty == true ? 
              errorData['errors'][0] : null);
    } catch (e) {
      logError('Failed to parse error message', e);
      return null;
    }
  }

  /// Safe JSON parsing
  static Map<String, dynamic> _parseJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (e) {
      logError('Failed to parse JSON', e);
      return {};
    }
  }

  /// Get user-friendly error message for any exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error is http.Response) {
      return handleHttpError(error);
    }
    
    final errorString = error.toString().toLowerCase();
    
    // Check for specific error types
    if (errorString.contains('socket') || 
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return handleNetworkError(error);
    } else if (errorString.contains('auth') || 
               errorString.contains('login') ||
               errorString.contains('token')) {
      return handleAuthError(error);
    } else if (errorString.contains('permission')) {
      return handlePermissionError(error);
    } else if (errorString.contains('file') || 
               errorString.contains('storage')) {
      return handleFileError(error);
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Show error dialog helper
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show error snackbar helper
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Show success snackbar helper
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Show warning snackbar helper
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Retry wrapper for async operations
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        if (attempt >= maxRetries) {
          logError('Max retries reached for ${operationName ?? 'operation'}', error);
          rethrow;
        }
        
        logWarning('Retry attempt $attempt for ${operationName ?? 'operation'}', error);
        await Future.delayed(delay * attempt); // Exponential backoff
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }
}