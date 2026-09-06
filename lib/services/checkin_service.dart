import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';

final checkinServiceProvider = Provider<CheckinService>((ref) {
  return CheckinService(ref.read(apiClientProvider));
});

class CheckinService {
  final ApiClient _api;
  CheckinService(this._api);

  Future<void> submitCheckin({
    required int overall,
    required int sleep,
    required int physical,
    required int focus,
    String? note,
  }) async {
    try {
      await _api.dio.post('/wellness/checkin', data: {
        'overall_score': overall,
        'sleep_score': sleep,
        'physical_score': physical,
        'focus_score': focus,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception("Check-in already submitted for today");
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkTodayStatus() async {
    try {
      final res = await _api.dio.get('/wellness/today');
      return res.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final res = await _api.dio.get('/wellness/history');
      return res.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
