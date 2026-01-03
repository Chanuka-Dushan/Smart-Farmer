class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? profilePictureUrl;
  final bool isBanned;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.phoneNumber,
    this.address,
    this.profilePictureUrl,
    required this.isBanned,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] is String ? json['phone_number'] : null,
      address: json['address'] is String ? json['address'] : null,
      profilePictureUrl: json['profile_picture_url'] is String ? json['profile_picture_url'] : null,
      isBanned: json['is_banned'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'profile_picture_url': profilePictureUrl,
      'is_banned': isBanned,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstname $lastname';
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final dynamic user; // Can be User or Seller

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Parse user data - check if it's a seller or regular user
    final userData = json['user'] ?? {};
    dynamic parsedUser;
    
    // Check if it has seller-specific fields
    if (userData['business_name'] != null) {
      // It's a seller
      parsedUser = userData; // Keep as map for now, will be parsed in AuthProvider
    } else {
      // It's a regular user
      parsedUser = User.fromJson(userData);
    }
    
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      user: parsedUser,
    );
  }
}
