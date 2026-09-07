import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<Map<String, dynamic>> activateDevice(String code, String pin, String fullName) async {
    try {
      final res = await _api.dio.post('/auth/mobile/activate', data: {
        'activation_code': code,
        'pin': pin,
        'full_name': fullName,
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
      return res.data['user'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String serviceId, String pin) async {
    try {
      final res = await _api.dio.post('/auth/mobile/login', data: {
        'service_id': serviceId,
        'pin': pin,
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
      return res.data['user'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
  }

  Future<void> deleteMyData() async {
    try {
      await _api.dio.delete('/users/me/data');
    } catch (_) {}
    await _api.clearToken();
  }
}
