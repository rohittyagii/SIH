import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(ref.read(apiClientProvider));
});

class SupportService {
  final ApiClient _api;
  SupportService(this._api);

  Future<void> requestCallback() async {
    try {
      await _api.dio.post('/support/callback', data: {
        'type': 'callback',
        'urgency': 'high',
      });
    } catch (e) {
      rethrow;
    }
  }
}
