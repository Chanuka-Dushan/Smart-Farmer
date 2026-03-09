class ResolvedPart {
  final int id;
  final String name;
  final String machineModel;
  final String? brand;
  final String? category;

  ResolvedPart({
    required this.id,
    required this.name,
    required this.machineModel,
    this.brand,
    this.category,
  });

  factory ResolvedPart.fromJson(Map<String, dynamic> json) {
    return ResolvedPart(
      id: ((json['id'] ?? json['part_id'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '').toString(),
      machineModel: (json['machine_model'] ?? '').toString(),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
    );
  }
}

class AlternativePart {
  final int partId;
  final String name;
  final String machineModel;
  final String? brand;
  final double score;
  final String? category;
  final double? price;
  final int? lifespan;
  final List<String> explanation;

  AlternativePart({
    required this.partId,
    required this.name,
    required this.machineModel,
    required this.score,
    this.brand,
    this.category,
    this.price,
    this.lifespan,
    required this.explanation,
  });

  factory AlternativePart.fromJson(Map<String, dynamic> json) {
    return AlternativePart(
      partId: ((json['recommended_part'] ?? json['part_id'] ?? json['id'] ?? 0)
              as num)
          .toInt(),
      name: (json['name'] ?? '').toString(),
      machineModel: (json['machine_model'] ?? '').toString(),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      score: ((json['similarity_percentage'] ??
                  json['final_score'] ??
                  json['score'] ??
                  json['similarity'] ??
                  0) as num)
              .toDouble(),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      lifespan:
          json['lifespan'] != null ? (json['lifespan'] as num).toInt() : null,
      explanation: (json['explanation'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class RecommendationResponse {
  final ResolvedPart queryPart;
  final int totalCandidates;
  final List<AlternativePart> recommendations;

  RecommendationResponse({
    required this.queryPart,
    required this.totalCandidates,
    required this.recommendations,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      queryPart: ResolvedPart.fromJson(
        (json['query_part'] ?? json['base_part'] ?? {}) as Map<String, dynamic>,
      ),
      totalCandidates: ((json['total_candidates'] ?? 0) as num).toInt(),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((e) => AlternativePart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}