import 'package:dio/dio.dart';

import 'models/items.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<List<Item>> fetchItems(String userId) async {
    final response = await _dio.get(
      "/items",
      queryParameters: {
        "user_id": userId,
      },
    );

    return (response.data as List)
        .map((e) => Item.fromJson(e))
        .toList();
  }


  Future<dynamic> processMessage({
    required String userId,
    required String message,
    String sender = "",
    String source = "sms",
  }) async {
    final response = await _dio.post(
      "/process-message",
      data: {
        "user_id": userId,
        "message": message,
        "sender": sender,
        "source": source,
      },
    );

    return response.data;
  }
}
