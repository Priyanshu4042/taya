import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Dio _dio = Dio();

  Future<void> createTestCalendarEvent() async {
    try {
      // Get the current Supabase session
      final Session? session = _supabase.auth.currentSession;

      if (session == null) {
        throw Exception('User is not signed in');
      }

      // This is the Google OAuth access token
      // NOT the Supabase session access token
      final String? googleAccessToken = session.providerToken;

      if (googleAccessToken == null) {
        throw Exception(
          'Google provider access token is not available',
        );
      }

      print('Google access token obtained');

      final response = await _dio.post(
        'http://localhost:8000/calendar/create',
        data: {
          "user_id": "3fa0819f-e660-4ce0-8a6c-f73e7a52632f",
          "title": "Placement Preparation",
          "description": "Practice DSA and revise core CS concepts",
          "start_time": "2026-07-22T18:00:00+05:30",
          "end_time": "2026-07-22T19:00:00+05:30",
          "timezone": "Asia/Kolkata"
        },
      );

      print('Event created successfully');
      print(response.data);
    } on DioException catch (e) {
      print('Status code: ${e.response?.statusCode}');
      print('Backend response: ${e.response?.data}');
      print('Dio error: ${e.message}');

      rethrow;
    } catch (e) {
      print('Error creating calendar event: $e');
      rethrow;
    }
  }
}