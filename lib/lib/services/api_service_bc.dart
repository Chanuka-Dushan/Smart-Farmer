import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {

  static Future<dynamic> post(String endpoint, Map data) async {

    final response = await http.post(
      Uri.parse(ApiConfig.baseUrl + endpoint),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  static Future<dynamic> get(String endpoint) async {

    final response = await http.get(
      Uri.parse(ApiConfig.baseUrl + endpoint),
    );

    return jsonDecode(response.body);
  }
}