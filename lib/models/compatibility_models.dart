class ResolvedPart {
  final int id;
  final String name;
  final String machineModel;
  final String? brand;
  final String? category;

  // Phase 2 / Phase 3 / Phase 4 fields
  final String? machineFamily;
  final String? compatibilityGroup;
  final String? functionType;
  final String? substituteLevel;
  final double? confidenceScore;
  final String? evidenceSource;

  ResolvedPart({
    required this.id,
    required this.name,
    required this.machineModel,
    this.brand,
    this.category,
    this.machineFamily,
    this.compatibilityGroup,
    this.functionType,
    this.substituteLevel,
    this.confidenceScore,
    this.evidenceSource,
  });

  factory ResolvedPart.fromJson(dynamic json) {
    if (json is String) {
      return ResolvedPart(
        id: 0,
        name: json,
        machineModel: '',
      );
    }

    if (json is Map<String, dynamic>) {
      return ResolvedPart(
        id: _toInt(json['id'] ?? json['part_id'] ?? json['query_part_id']),
        name: _toStringValue(
          json['name'] ??
              json['part_name'] ??
              json['part'] ??
              json['query_part'],
        ),
        machineModel: _toStringValue(
          json['machine_model'] ??
              json['model'] ??
              json['machine'] ??
              json['machine_name'],
        ),
        brand: _toNullableString(json['brand']),
        category: _toNullableString(json['category']),
        machineFamily: _toNullableString(json['machine_family']),
        compatibilityGroup: _toNullableString(json['compatibility_group']),
        functionType: _toNullableString(json['function_type']),
        substituteLevel: _toNullableString(json['substitute_level']),
        confidenceScore: _toNullableScorePercentage(json['confidence_score']),
        evidenceSource: _toNullableString(json['evidence_source']),
      );
    }

    return ResolvedPart(
      id: 0,
      name: '',
      machineModel: '',
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

  // Phase 2 / Phase 3 / Phase 4 fields
  final String? machineFamily;
  final String? compatibilityGroup;
  final String? functionType;
  final String? substituteLevel;
  final double? confidenceScore;
  final String? evidenceSource;

  final double similarityScore;
  final double mlScore;
  final double feedbackScore;

  final String? whyRecommended;
  final List<String> matchedFields;
  final Map<String, dynamic> differences;

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
    this.machineFamily,
    this.compatibilityGroup,
    this.functionType,
    this.substituteLevel,
    this.confidenceScore,
    this.evidenceSource,
    required this.similarityScore,
    required this.mlScore,
    required this.feedbackScore,
    this.whyRecommended,
    required this.matchedFields,
    required this.differences,
  });

  factory AlternativePart.fromJson(dynamic json) {
    if (json is String) {
      return AlternativePart(
        partId: 0,
        name: json,
        machineModel: '',
        score: 0,
        explanation: const [],
        similarityScore: 0,
        mlScore: 0,
        feedbackScore: 0,
        matchedFields: const [],
        differences: const {},
      );
    }

    if (json is Map<String, dynamic>) {
      final dynamic idValue =
          json['recommended_part_id'] ??
          json['recommended_part'] ??
          json['part_id'] ??
          json['id'];

      return AlternativePart(
        partId: _toInt(idValue),
        name: _toStringValue(
          json['name'] ??
              json['part_name'] ??
              json['recommended_part_name'] ??
              json['recommended_part'],
        ),
        machineModel: _toStringValue(
          json['machine_model'] ??
              json['model'] ??
              json['machine'] ??
              json['machine_name'],
        ),
        brand: _toNullableString(json['brand']),
        category: _toNullableString(json['category']),

        // Backend sends final_score like 0.9116.
        // Frontend needs 91.16 for filtering and display.
        score: _toScorePercentage(
          json['final_score'] ??
              json['compatibility_score'] ??
              json['similarity_percentage'] ??
              json['score'] ??
              json['similarity'],
        ),

        price: _toNullableDouble(json['price']),
        lifespan: _toNullableInt(json['lifespan']),

        explanation: _toExplanationList(
          json['explanation'] ?? json['why_explanation'],
        ),

        machineFamily: _toNullableString(json['machine_family']),
        compatibilityGroup: _toNullableString(json['compatibility_group']),
        functionType: _toNullableString(json['function_type']),
        substituteLevel: _toNullableString(json['substitute_level']),
        confidenceScore: _toNullableScorePercentage(json['confidence_score']),
        evidenceSource: _toNullableString(json['evidence_source']),

        similarityScore: _toScorePercentage(
          json['similarity_score'] ??
              json['vector_similarity_score'] ??
              json['similarity_percentage'],
        ),
        mlScore: _toScorePercentage(json['ml_score'] ?? json['rf_score']),
        feedbackScore: _toScorePercentage(json['feedback_score']),

        whyRecommended: _extractWhyRecommended(json),
        matchedFields: _extractMatchedFields(json),
        differences: _extractDifferences(json),
      );
    }

    return AlternativePart(
      partId: 0,
      name: '',
      machineModel: '',
      score: 0,
      explanation: const [],
      similarityScore: 0,
      mlScore: 0,
      feedbackScore: 0,
      matchedFields: const [],
      differences: const {},
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
    // Backend may return:
    // {
    //   "query_part": "Clutch Finger",
    //   "query_part_id": 70
    // }
    // So we manually build a map for ResolvedPart when query_part is a string.
    final dynamic queryRaw = json['query_part'] is Map
        ? json['query_part']
        : {
            'id': json['query_part_id'] ??
                json['part_id'] ??
                json['original_part_id'] ??
                json['id'],
            'part_id': json['query_part_id'] ??
                json['part_id'] ??
                json['original_part_id'] ??
                json['id'],
            'name': json['query_part'] ??
                json['part_name'] ??
                json['name'] ??
                json['original_part_name'],
            'machine_model':
                json['query_machine_model'] ?? json['machine_model'],
            'brand': json['brand'],
            'category': json['category'],
            'machine_family': json['machine_family'],
            'compatibility_group': json['compatibility_group'],
            'function_type': json['function_type'],
          };

    final dynamic recommendationsRaw =
        json['recommendations'] ??
        json['recommended_parts'] ??
        json['alternatives'] ??
        [];

    return RecommendationResponse(
      queryPart: ResolvedPart.fromJson(queryRaw),
      totalCandidates: _toInt(
        json['total_candidates'] ??
            json['candidate_count'] ??
            json['total'] ??
            (recommendationsRaw is List ? recommendationsRaw.length : 0),
      ),
      recommendations: recommendationsRaw is List
          ? recommendationsRaw
              .map((e) => AlternativePart.fromJson(e))
              .where((part) => part.name.trim().isNotEmpty)
              .toList()
          : [],
    );
  }
}

// -----------------------------
// Safe helper methods
// -----------------------------

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double _toScorePercentage(dynamic value) {
  final score = _toDouble(value);

  // Convert 0.9116 to 91.16
  if (score > 0 && score <= 1) {
    return score * 100;
  }

  // Already percentage, for example 91.16
  return score;
}

double? _toNullableScorePercentage(dynamic value) {
  if (value == null) return null;

  final score = _toDouble(value);

  if (score > 0 && score <= 1) {
    return score * 100;
  }

  return score;
}

String _toStringValue(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<String> _toStringList(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return [value];
  }

  return const [];
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val),
    );
  }

  return const {};
}

// -----------------------------
// Phase 4 nested explanation helpers
// -----------------------------

List<String> _toExplanationList(dynamic value) {
  if (value == null) return const [];

  if (value is Map) {
    final List<String> items = [];

    final why = value['why_recommended'];
    if (why != null && why.toString().trim().isNotEmpty) {
      items.add(why.toString());
    }

    final notes = value['notes'];
    if (notes is List) {
      items.addAll(notes.map((e) => e.toString()));
    }

    return items;
  }

  return _toStringList(value);
}

String? _extractWhyRecommended(Map<String, dynamic> json) {
  final direct = _toNullableString(json['why_recommended']);
  if (direct != null) return direct;

  final explanation = json['explanation'];
  if (explanation is Map) {
    return _toNullableString(explanation['why_recommended']);
  }

  return null;
}

List<String> _extractMatchedFields(Map<String, dynamic> json) {
  final direct = json['matched_fields'];
  if (direct is List) {
    return direct.map((e) => e.toString()).toList();
  }

  if (direct is Map) {
    return direct.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key.toString())
        .toList();
  }

  final explanation = json['explanation'];
  if (explanation is Map) {
    final nested = explanation['matched_fields'];

    if (nested is List) {
      return nested.map((e) => e.toString()).toList();
    }

    if (nested is Map) {
      return nested.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .toList();
    }
  }

  return const [];
}

Map<String, dynamic> _extractDifferences(Map<String, dynamic> json) {
  final direct = json['differences'];
  if (direct != null) {
    return _toMap(direct);
  }

  final explanation = json['explanation'];
  if (explanation is Map) {
    return _toMap(explanation['differences']);
  }

  return const {};
}