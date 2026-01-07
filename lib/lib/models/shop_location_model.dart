class ShopLocation {
  final int id;
  final String businessName;
  final String latitude;
  final String longitude;
  final String? shopLocationName;
  final String? businessAddress;
  final String? phoneNumber;
  final String? businessDescription;

  ShopLocation({
    required this.id,
    required this.businessName,
    required this.latitude,
    required this.longitude,
    this.shopLocationName,
    this.businessAddress,
    this.phoneNumber,
    this.businessDescription,
  });

  factory ShopLocation.fromJson(Map<String, dynamic> json) {
    return ShopLocation(
      id: json['id'] ?? 0,
      businessName: json['business_name'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      shopLocationName: json['shop_location_name'],
      businessAddress: json['business_address'],
      phoneNumber: json['phone_number'],
      businessDescription: json['business_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'latitude': latitude,
      'longitude': longitude,
      'shop_location_name': shopLocationName,
      'business_address': businessAddress,
      'phone_number': phoneNumber,
      'business_description': businessDescription,
    };
  }

  double get lat => double.tryParse(latitude) ?? 0.0;
  double get lng => double.tryParse(longitude) ?? 0.0;
}