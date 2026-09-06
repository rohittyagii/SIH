import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// Use 10.0.2.2 for Android emulator, localhost for iOS simulator.
final _baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8000/api/v1' : 'http://localhost:8000/api/v1';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(const FlutterSecureStorage());
});

class ApiClient {
  final FlutterSecureStorage _storage;
  late final Dio _dio;
  
  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        // You can handle 401 Unauthorized globally here
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }
}
