import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compatibility_models.dart';
import 'api_constants.dart';

class CompatibilityService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ----------------------------------------------------------
  // Fetch machine models
  // Backend example:
  // GET /api/parts/machine-models
  // ----------------------------------------------------------
  static Future<List<String>> fetchMachineModels() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.machineModels}',
    );

    final response = await http.get(uri, headers: _headers);
    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(_extractError(data, 'Failed to load machine models'));
    }

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }

    if (data is Map && data['machine_models'] is List) {
      return (data['machine_models'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return [];
  }

  // ----------------------------------------------------------
  // Resolve/search part
  // Backend example:
  // GET /search?q=clutch+finger&top_k=10
  // ----------------------------------------------------------
  static Future<ResolvedPart> resolvePart({
    required String machineModel,
    required String partText,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.resolvePart}'
      '?q=${Uri.encodeQueryComponent(partText)}'
      '&top_k=10',
    );

    final response = await http.get(uri, headers: _headers);
    final data = _decodeResponse(response);

    print('SEARCH URL: $uri');
    print('SEARCH STATUS: ${response.statusCode}');
    print('SEARCH BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(data, 'Unable to identify part'));
    }

    if (data is! Map || data['results'] is! List) {
      throw Exception('Invalid search response');
    }

    final List results = data['results'] as List;

    if (results.isEmpty) {
      throw Exception('Part not found');
    }

    final List machineMatched = results.where((item) {
      if (item is! Map) return false;

      final model = (item['machine_model'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      return model == machineModel.trim().toLowerCase();
    }).toList();

    final selected =
        machineMatched.isNotEmpty ? machineMatched.first : results.first;

    return ResolvedPart.fromJson(selected);
  }

  // ----------------------------------------------------------
  // Fetch recommendations
  // Backend example:
  // GET /recommend/70
  // ----------------------------------------------------------
  static Future<RecommendationResponse> fetchRecommendations(int partId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.recommend}/$partId',
    );

    final response = await http.get(uri, headers: _headers);
    final data = _decodeResponse(response);

    print('RECOMMENDATION URL: $uri');
    print('RECOMMENDATION STATUS: ${response.statusCode}');
    print('RECOMMENDATION BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(data, 'Failed to load recommendations'));
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid recommendation response format');
    }

    return RecommendationResponse.fromJson(data);
  }

  // ----------------------------------------------------------
  // Fetch comparison
  // Backend example:
  // GET /api/compare?original_part_id=70&alternative_part_id=71
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>> fetchComparison({
    required int baseId,
    required int altId,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.compare}'
      '?original_part_id=$baseId'
      '&alternative_part_id=$altId',
    );

    final response = await http.get(uri, headers: _headers);
    final data = _decodeResponse(response);

    print('COMPARISON URL: $uri');
    print('COMPARISON STATUS: ${response.statusCode}');
    print('COMPARISON BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(data, 'Failed to load comparison'));
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid comparison response format');
    }

    return data;
  }

  // ----------------------------------------------------------
  // Submit feedback
  // Backend example:
  // POST /api/feedback
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>> submitFeedback({
    required int queryPartId,
    required int recommendedPartId,
    required String feedback,
    String? reason,
    String userId = '1',
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.feedback}',
    );

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'part_id': queryPartId,
        'recommended_part_id': recommendedPartId,
        'feedback': feedback,
        'reason': reason,
      }),
    );

    final data = _decodeResponse(response);

    print('FEEDBACK URL: $uri');
    print('FEEDBACK STATUS: ${response.statusCode}');
    print('FEEDBACK BODY: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(data, 'Failed to submit feedback'));
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid feedback response format');
    }

    return data;
  }

  // ----------------------------------------------------------
  // Safe JSON decoder
  // ----------------------------------------------------------
  static dynamic _decodeResponse(http.Response response) {
    try {
      if (response.body.trim().isEmpty) {
        return {};
      }

      return jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid JSON response from server: ${response.body}',
      );
    }
  }

  // ----------------------------------------------------------
  // Safe backend error extractor
  // ----------------------------------------------------------
  static String _extractError(dynamic data, String fallback) {
    if (data is Map) {
      final detail = data['detail'] ?? data['message'] ?? data['error'];

      if (detail == null) return fallback;

      if (detail is String) return detail;

      return detail.toString();
    }

    return fallback;
  }
}