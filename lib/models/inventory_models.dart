class ForecastItem {
  final int partId;
  final String partName;
  final List<int> monthlyDemand;
  final double forecastNextMonth;

  ForecastItem({
    required this.partId,
    required this.partName,
    required this.monthlyDemand,
    required this.forecastNextMonth,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      partId: json['part_id'],
      partName: json['part_name'] ?? '',
      monthlyDemand: (json['monthly_demand'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      forecastNextMonth: (json['forecast_next_month'] as num).toDouble(),
    );
  }
}

class ReorderItem {
  final int partId;
  final String partName;
  final int currentStock;
  final int reorderPoint;
  final double forecastNextMonth;
  final int recommendedReorderQty;
  final String reason;

  ReorderItem({
    required this.partId,
    required this.partName,
    required this.currentStock,
    required this.reorderPoint,
    required this.forecastNextMonth,
    required this.recommendedReorderQty,
    required this.reason,
  });

  factory ReorderItem.fromJson(Map<String, dynamic> json) {
    return ReorderItem(
      partId: (json['part_id'] as num).toInt(),
      partName: json['part_name'] ?? '',
      currentStock: (json['current_stock'] as num).toInt(),
      reorderPoint: (json['reorder_point'] as num).toInt(),
      forecastNextMonth: (json['forecast_next_month'] as num).toDouble(),
      recommendedReorderQty:
          (json['recommended_reorder_qty'] as num).toInt(),
      reason: json['reason'] ?? '',
    );
  }
}

class SubstituteSuggestion {
  final int originalPartId;
  final String originalPartName;
  final int substitutePartId;
  final String substitutePartName;
  final double feedbackScore;
  final String reason;

  SubstituteSuggestion({
    required this.originalPartId,
    required this.originalPartName,
    required this.substitutePartId,
    required this.substitutePartName,
    required this.feedbackScore,
    required this.reason,
  });

  factory SubstituteSuggestion.fromJson(Map<String, dynamic> json) {
    return SubstituteSuggestion(
      originalPartId: (json['original_part_id'] as num).toInt(),
      originalPartName: json['original_part_name'] ?? '',
      substitutePartId: (json['substitute_part_id'] as num).toInt(),
      substitutePartName: json['substitute_part_name'] ?? '',
      feedbackScore: (json['feedback_score'] as num).toDouble(),
      reason: json['reason'] ?? '',
    );
  }
}

class InventoryRecommendationResponse {
  final List<ReorderItem> reorderList;
  final List<SubstituteSuggestion> suggestedSubstitutes;

  InventoryRecommendationResponse({
    required this.reorderList,
    required this.suggestedSubstitutes,
  });

  factory InventoryRecommendationResponse.fromJson(
      Map<String, dynamic> json) {
    return InventoryRecommendationResponse(
      reorderList: (json['reorder_list'] as List<dynamic>)
          .map((e) => ReorderItem.fromJson(e))
          .toList(),
      suggestedSubstitutes: (json['suggested_substitutes'] as List<dynamic>)
          .map((e) => SubstituteSuggestion.fromJson(e))
          .toList(),
    );
  }
}