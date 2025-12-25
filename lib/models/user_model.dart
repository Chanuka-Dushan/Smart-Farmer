class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? phoneNumber;
  final String? address;
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
      phoneNumber: json['phone_number'],
      address: json['address'],
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
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      user: json['user'] != null ? User.fromJson(json['user']) : User(
        id: 0,
        firstname: '',
        lastname: '',
        email: '',
        isBanned: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
