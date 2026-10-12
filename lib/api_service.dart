import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/items.dart';

class ApiService {
  static const String baseUrl = "https://taya-server-708184550477.asia-south1.run.app";
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client = http.Client();

  Future<List<Item>> fetchItems(String userId) async {
    final uri = Uri.parse("$baseUrl/items").replace(
      queryParameters: {
        "user_id": userId,
      },
    );

    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Failed to fetch items: ${response.statusCode} ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body) as List;
    return decoded.map((e) => Item.fromJson(e)).toList();
  }

  Future<dynamic> processMessage({
    required String userId,
    required String message,
    String sender = "",
    String source = "sms",
  }) async {
    final uri = Uri.parse("$baseUrl/process-message");

    final response = await _client
        .post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "message": message,
        "sender": sender,
        "source": source,
      }),
    )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Failed to process message: ${response.statusCode} ${response.body}",
      );
    }

    return jsonDecode(response.body);
  }

  void dispose() {
    _client.close();
  }
}