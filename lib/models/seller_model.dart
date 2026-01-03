class Seller {
  final int id;
  final String businessName;
  final String ownerFirstname;
  final String ownerLastname;
  final String email;
  final String? phoneNumber;
  final String? businessAddress;
  final String? businessDescription;
  final String? latitude;
  final String? longitude;
  final String? shopLocationName;
  final String? logoUrl;
  final bool onboardingCompleted;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Seller({
    required this.id,
    required this.businessName,
    required this.ownerFirstname,
    required this.ownerLastname,
    required this.email,
    this.phoneNumber,
    this.businessAddress,
    this.businessDescription,
    this.latitude,
    this.longitude,
    this.shopLocationName,
    this.logoUrl,
    this.onboardingCompleted = false,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] ?? 0,
      businessName: json['business_name'] ?? '',
      ownerFirstname: json['owner_firstname'] ?? '',
      ownerLastname: json['owner_lastname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] is String ? json['phone_number'] : null,
      businessAddress: json['business_address'] is String ? json['business_address'] : null,
      businessDescription: json['business_description'] is String ? json['business_description'] : null,
      latitude: json['latitude'] is String ? json['latitude'] : null,
      longitude: json['longitude'] is String ? json['longitude'] : null,
      shopLocationName: json['shop_location_name'] is String ? json['shop_location_name'] : null,
      logoUrl: json['logo_url'] is String ? json['logo_url'] : null,
      onboardingCompleted: json['onboarding_completed'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'owner_firstname': ownerFirstname,
      'owner_lastname': ownerLastname,
      'email': email,
      'phone_number': phoneNumber,
      'business_address': businessAddress,
      'business_description': businessDescription,
      'latitude': latitude,
      'longitude': longitude,
      'shop_location_name': shopLocationName,
      'logo_url': logoUrl,
      'onboarding_completed': onboardingCompleted,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get ownerFullName => '$ownerFirstname $ownerLastname';
}