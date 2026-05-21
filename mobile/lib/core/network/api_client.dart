import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../constants/api_constants.dart';

class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${await _storage.read(key: 'access_token')}';
            final clone = await _dio.fetch(opts);
            return handler.resolve(clone);
          }
        }
        handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  String? _deviceUuid;

  Dio get dio => _dio;

  Future<String> get deviceUuid async {
    _deviceUuid ??= await _storage.read(key: 'device_uuid');
    if (_deviceUuid == null) {
      _deviceUuid = const Uuid().v4();
      await _storage.write(key: 'device_uuid', value: _deviceUuid);
    }
    return _deviceUuid!;
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<bool> _refreshToken() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;

    try {
      final res = await _dio.post('/auth/refresh', data: {'refresh_token': refresh});
      await saveTokens(res.data['access_token'], res.data['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }
}
