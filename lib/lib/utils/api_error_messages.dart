/// API Error Messages Helper
/// 
/// Provides user-friendly error messages for common API errors
class ApiErrorMessages {
  // Authentication errors
  static const String invalidCredentials = 'Invalid email or password';
  static const String accountBanned = 'Your account has been banned. Please contact support.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  static const String notAuthenticated = 'You must be logged in to perform this action.';
  
  // Registration errors
  static const String emailAlreadyExists = 'This email is already registered';
  static const String registrationFailed = 'Registration failed. Please try again.';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  
  // Profile errors
  static const String profileUpdateFailed = 'Failed to update profile. Please try again.';
  static const String profileFetchFailed = 'Failed to load profile. Please try again.';
  
  // Password errors
  static const String incorrectOldPassword = 'Current password is incorrect';
  static const String passwordChangeFailed = 'Failed to change password. Please try again.';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  
  // Account errors
  static const String accountDeletionFailed = 'Failed to delete account. Please try again.';
  
  // Network errors
  static const String noInternetConnection = 'No internet connection. Please check your network.';
  static const String requestTimeout = 'Request timed out. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  
  /// Parse error from exception message
  static String parseError(String errorMessage) {
    final lowercaseError = errorMessage.toLowerCase();
    
    // Authentication errors
    if (lowercaseError.contains('invalid email') || 
        lowercaseError.contains('invalid password') ||
        lowercaseError.contains('invalid credentials')) {
      return invalidCredentials;
    }
    
    if (lowercaseError.contains('banned') || lowercaseError.contains('403')) {
      return accountBanned;
    }
    
    if (lowercaseError.contains('session expired') || 
        lowercaseError.contains('token expired') ||
        lowercaseError.contains('401')) {
      return sessionExpired;
    }
    
    // Registration errors
    if (lowercaseError.contains('email already') || 
        lowercaseError.contains('already registered')) {
      return emailAlreadyExists;
    }
    
    // Password errors
    if (lowercaseError.contains('incorrect') && lowercaseError.contains('password')) {
      return incorrectOldPassword;
    }
    
    if (lowercaseError.contains('password') && lowercaseError.contains('short')) {
      return passwordTooShort;
    }
    
    // Network errors
    if (lowercaseError.contains('socketexception') || 
        lowercaseError.contains('no internet') ||
        lowercaseError.contains('network')) {
      return noInternetConnection;
    }
    
    if (lowercaseError.contains('timeout')) {
      return requestTimeout;
    }
    
    if (lowercaseError.contains('500') || 
        lowercaseError.contains('502') ||
        lowercaseError.contains('503')) {
      return serverError;
    }
    
    // Return cleaned error message
    return errorMessage.replaceAll('Exception: ', '');
  }
  
  /// Get HTTP status code message
  static String getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return sessionExpired;
      case 403:
        return accountBanned;
      case 404:
        return 'Resource not found.';
      case 408:
        return requestTimeout;
      case 409:
        return 'Conflict. This resource already exists.';
      case 422:
        return 'Invalid data provided.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return serverError;
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Error $statusCode: $unknownError';
    }
  }
}
