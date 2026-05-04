import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InventoryService {
  static const String baseUrl = kIsWeb
      ? "http://127.0.0.1:8000"
      : "http://10.0.2.2:8000";

  Future<Map<String, dynamic>> predictInventory({
    String? month,
    String? season,
    String? stage,
    String? category,
    String? model,
    String? type,
    bool flatten = false,
  }) async {
    final queryParams = <String, String>{};

    if (month != null && month.isNotEmpty) queryParams['month'] = month;
    if (season != null && season.isNotEmpty) queryParams['season'] = season;
    if (stage != null && stage.isNotEmpty) queryParams['stage'] = stage;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (model != null && model.isNotEmpty) queryParams['model'] = model;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    queryParams['flatten'] = flatten.toString();

    final uri = Uri.parse("$baseUrl/api/inventory/predict").replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractErrorMessage(response.body, 'Prediction failed'));
    }
  }

  Future<Map<String, dynamic>> analyzeStock({
    required List<Map<String, dynamic>> predictedItems,
    required List<Map<String, dynamic>> vendorStock,
  }) async {
    final uri = Uri.parse("$baseUrl/api/inventory/stock/analyze");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "predictedItems": predictedItems,
        "vendorStock": vendorStock,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        _extractErrorMessage(response.body, 'Stock analysis failed'),
      );
    }
  }

  Future<Map<String, dynamic>> analyzeStockExcel({
    required List<Map<String, dynamic>> predictedItems,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final uri = Uri.parse("$baseUrl/api/inventory/stock/analyze-excel");

    final request = http.MultipartRequest('POST', uri);

    request.fields['predictedItems'] = jsonEncode(predictedItems);

    if (kIsWeb) {
      if (fileBytes == null || fileName == null || fileName.isEmpty) {
        throw Exception("Excel file bytes or file name missing for web upload");
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
    } else {
      if (filePath == null || filePath.isEmpty) {
        throw Exception("Excel file path missing");
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception(
        _extractErrorMessage(responseBody, 'Excel stock analysis failed'),
      );
    }
  }

  String _extractErrorMessage(String responseBody, String fallbackMessage) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        if (detail is String) {
          return detail;
        }

        if (detail is List) {
          return detail.map((e) => e.toString()).join(', ');
        }

        if (detail != null) {
          return detail.toString();
        }
      }

      return fallbackMessage;
    } catch (_) {
      return fallbackMessage;
    }
  }
}