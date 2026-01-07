import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecommendationService {
  // ==========================================================
  // 🔹 Base URL
  // ==========================================================
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    if (Platform.isIOS) return "http://localhost:8000";
    return "http://localhost:8000";
  }

  // ==========================================================
  // 🤖 Hybrid Recommendation
  // ==========================================================
  static Future<Map<String, dynamic>> getHybridRecommendations(
      int partId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recommend/hybrid/$partId"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to load recommendations");
  }

  // ==========================================================
  // Comparison
  // ==========================================================
  static Future<Map<String, dynamic>> getComparison(
      int baseId, int altId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recommend/compare/$baseId/$altId"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to load comparison");
  }
}
