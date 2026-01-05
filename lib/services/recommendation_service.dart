import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecommendationService {
  /// 🔹 Central base URL selector
  static String get baseUrl {
    // 🌐 Flutter Web (Chrome)
    if (kIsWeb) {
      return "http://localhost:8000";
    }

    // 🤖 Android
    if (Platform.isAndroid) {
      // Android Emulator
      return "http://10.0.2.2:8000";

      // 📱 Physical Android Device
      // return "http://192.168.1.100:8000"; // <-- replace with your PC IP
    }

    // 🍎 iOS Simulator
    if (Platform.isIOS) {
      return "http://localhost:8000";
    }

    // Fallback (safe default)
    return "http://localhost:8000";
  }

  // ==========================================================
  // Hybrid Recommendation API
  // ==========================================================
  static Future<Map<String, dynamic>> getHybridRecommendations(
      int partId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recommend/hybrid/$partId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "Failed to load recommendations (${response.statusCode})",
      );
    }
  }

  // ==========================================================
  // Comparison API
  // ==========================================================
  static Future<Map<String, dynamic>> getComparison(
      int baseId, int altId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recommend/compare/$baseId/$altId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "Failed to load comparison (${response.statusCode})",
      );
    }
  }
}
