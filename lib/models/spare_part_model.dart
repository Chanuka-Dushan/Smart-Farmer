class SparePartRequest {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;

  SparePartRequest({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory SparePartRequest.fromJson(Map<String, dynamic> json) {
    return SparePartRequest(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SparePartOffer {
  final int id;
  final int requestId;
  final int sellerId;
  final String price;
  final String description;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? seller;

  SparePartOffer({
    required this.id,
    required this.requestId,
    required this.sellerId,
    required this.price,
    required this.description,
    required this.status,
    required this.createdAt,
    this.seller,
  });

  factory SparePartOffer.fromJson(Map<String, dynamic> json) {
    return SparePartOffer(
      id: json['id'],
      requestId: json['request_id'],
      sellerId: json['seller_id'],
      price: json['price'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      seller: json['seller'],
    );
  }
}
