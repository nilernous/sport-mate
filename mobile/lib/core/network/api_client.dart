import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';
import '../errors/app_exception.dart';
import 'token_storage.dart';

/// The single configured HTTP client. Attaches the bearer token, converts
/// failures into [AppException] and reports 401s so the session can be cleared.
class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        final hadToken = error.requestOptions.headers.containsKey('Authorization');
        if (error.response?.statusCode == 401 && hadToken) onUnauthorized?.call();
        handler.next(error.copyWith(error: AppException.fromDio(error)));
      },
    ));
  }

  final TokenStorage _tokens;
  late final Dio _dio;

  /// Set by the auth layer: called when a request with a token is rejected (revoked or expired).
  void Function()? onUnauthorized;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: _clean(query)));

  Future<T> post<T>(String path, {Object? data, Map<String, String>? headers}) =>
      _send(() => _dio.post<T>(path, data: data, options: Options(headers: headers)));

  Future<T> put<T>(String path, {Object? data}) => _send(() => _dio.put<T>(path, data: data));

  Future<T> patch<T>(String path, {Object? data}) => _send(() => _dio.patch<T>(path, data: data));

  Future<T> delete<T>(String path) => _send(() => _dio.delete<T>(path));

  /// Multipart upload (e.g. product images).
  Future<T> postForm<T>(String path, FormData form) =>
      _send(() => _dio.post<T>(path, data: form, options: Options(contentType: 'multipart/form-data')));

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final result = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      result[key] = value;
    });
    return result;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStorageProvider)));
