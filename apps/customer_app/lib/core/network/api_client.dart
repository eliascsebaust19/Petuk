import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import 'api_exception.dart';

/// Provides the current bearer token (from the persisted session).
typedef TokenProvider = Future<String?> Function();

/// Thin, fully-configured Dio wrapper for the Phase 2 REST backend.
///
/// Phase 1 repositories are mock/local, but the transport is production
/// ready: timeouts for slow 2G/3G networks, auth header injection and
/// localized error mapping via [ApiException].
class ApiClient {
  ApiClient({String? baseUrl, TokenProvider? tokenProvider, Dio? dio})
      : _tokenProvider = tokenProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 12),
                sendTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                responseType: ResponseType.json,
                headers: <String, String>{'Accept': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          final String? token = await _tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (Object object) => debugPrint('[API] $object'),
        ),
      );
    }
  }

  final Dio _dio;
  final TokenProvider? _tokenProvider;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) {
    return _run<T>(() => _dio.get<T>(path, queryParameters: query));
  }

  Future<T> post<T>(String path, {Object? body}) {
    return _run<T>(() => _dio.post<T>(path, data: body));
  }

  Future<T> patch<T>(String path, {Object? body}) {
    return _run<T>(() => _dio.patch<T>(path, data: body));
  }

  Future<T> delete<T>(String path) {
    return _run<T>(() => _dio.delete<T>(path));
  }

  Future<T> _run<T>(Future<Response<T>> Function() request) async {
    try {
      final Response<T> response = await request();
      final T? data = response.data;
      if (data == null) {
        throw const ApiException('সার্ভার থেকে খালি উত্তর এসেছে।');
      }
      return data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
