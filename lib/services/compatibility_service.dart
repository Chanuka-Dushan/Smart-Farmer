import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compatibility_models.dart';
import 'api_constants.dart';

class CompatibilityService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  static Future<List<String>> fetchMachineModels() async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.machineModels}');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load machine models');
    }

    final data = jsonDecode(response.body);

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
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data is Map
            ? data['detail'] ?? 'Unable to identify part'
            : 'Unable to identify part',
      );
    }

    if (data is! Map || data['results'] is! List) {
      throw Exception('Invalid search response');
    }

    final List results = data['results'] as List;

    if (results.isEmpty) {
      throw Exception('Part not found');
    }

    final List machineMatched = results.where((item) {
      final model =
          (item['machine_model'] ?? '').toString().trim().toLowerCase();
      return model == machineModel.trim().toLowerCase();
    }).toList();

    final selected = machineMatched.isNotEmpty ? machineMatched.first : results.first;

    return ResolvedPart(
      id: ((selected['part_id'] ?? 0) as num).toInt(),
      name: (selected['name'] ?? '').toString(),
      machineModel: (selected['machine_model'] ?? '').toString(),
      brand: selected['brand']?.toString(),
      category: selected['category']?.toString(),
    );
  }

  static Future<RecommendationResponse> fetchRecommendations(int partId) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recommend}/$partId');
    final response = await http.get(uri, headers: _headers);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Failed to load recommendations');
    }

    return RecommendationResponse.fromJson(data);
  }

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
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Failed to load comparison');
    }

    return data;
  }

  static Future<Map<String, dynamic>> submitFeedback({
    required int queryPartId,
    required int recommendedPartId,
    required String feedback,
    String? reason,
    String userId = '1',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.feedback}');
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

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['detail'] ?? 'Failed to submit feedback');
    }

    return data;
  }
}