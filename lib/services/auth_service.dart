import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

class AuthService {
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  AuthService(this._api);

  Future<Map<String, dynamic>> activateDevice(
      String code, String pin, String fullName) async {
    try {
      final res = await _api.dio.post('/auth/mobile/activate', data: {
        'activation_code': code,
        'pin': pin,
        'full_name': fullName,
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
      await _storage.write(
          key: 'local_pin', value: pin); // Cache PIN for offline
      return res.data['user'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String serviceId, String pin) async {
    // 1. Try local offline validation first for instant login
    final localPin = await _storage.read(key: 'local_pin');
    if (localPin != null && localPin == pin) {
      // Trigger background login to wake server and get a fresh token
      _backgroundLogin(serviceId, pin);
      return {'service_id': serviceId, 'name': 'User'};
    }

    // 2. If local validation fails or no local PIN exists, fallback to API
    try {
      final res = await _api.dio.post('/auth/mobile/login', data: {
        'service_id': serviceId,
        'pin': pin,
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
      await _storage.write(
          key: 'local_pin', value: pin); // Cache PIN for future offline logins
      return res.data['user'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _backgroundLogin(String serviceId, String pin) async {
    try {
      final res = await _api.dio.post('/auth/mobile/login', data: {
        'service_id': serviceId,
        'pin': pin,
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
    } catch (_) {}
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
    await _storage.delete(key: 'local_pin'); // Clear PIN on full deletion
  }

  Future<void> changePin(String currentPin, String newPin) async {
    try {
      await _api.dio.post('/auth/mobile/change-pin', data: {
        'current_pin': currentPin,
        'new_pin': newPin,
      });
      await _storage.write(
          key: 'local_pin', value: newPin); // Update cached PIN
    } catch (e) {
      // If API fails, we could theoretically do an offline pin change, but better to require online for changes.
      rethrow;
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      await _api.dio.patch('/users/me/preferences', data: prefs);
    } catch (_) {}
  }
}
