import 'package:dio/dio.dart';

/// User-facing API failure carrying a Bangla message, safe to render
/// directly in snackbars and error views.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Maps every [DioExceptionType] to a localized, actionable message.
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'সার্ভার সাড়া দিচ্ছে না। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। ডেটা চালু করে আবার চেষ্টা করুন।',
        );
      case DioExceptionType.badCertificate:
        return const ApiException('নিরাপদ সংযোগ তৈরি করা যায়নি।');
      case DioExceptionType.badResponse:
        final int? code = error.response?.statusCode;
        final Object? data = error.response?.data;
        if (data is Map<String, dynamic>) {
          final Object? serverMessage = data['message'];
          if (serverMessage is String && serverMessage.isNotEmpty) {
            return ApiException(serverMessage, statusCode: code);
          }
        }
        if (code == 401 || code == 403) {
          return ApiException(
            'সেশনের মেয়াদ শেষ। আবার লগইন করুন।',
            statusCode: code,
          );
        }
        if (code != null && code >= 500) {
          return ApiException(
            'সার্ভারে সমস্যা হচ্ছে। কিছুক্ষণ পর আবার চেষ্টা করুন।',
            statusCode: code,
          );
        }
        return ApiException('অনুরোধটি সম্পন্ন করা যায়নি।', statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('অনুরোধটি বাতিল করা হয়েছে।');
      case DioExceptionType.unknown:
        return const ApiException('অপ্রত্যাশিত সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
