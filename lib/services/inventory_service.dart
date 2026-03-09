import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/inventory_models.dart';

class InventoryService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<ForecastItem>> fetchInventoryForecast(String vendorId) async {
    final url = Uri.parse('$baseUrl/inventory/forecast?vendor_id=$vendorId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ForecastItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load inventory forecast');
    }
  }

  Future<InventoryRecommendationResponse> fetchInventoryRecommendations(
    String vendorId,
  ) async {
    final url = Uri.parse('$baseUrl/inventory/recommend?vendor_id=$vendorId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return InventoryRecommendationResponse.fromJson(data);
    } else {
      throw Exception('Failed to load inventory recommendations');
    }
  }
}