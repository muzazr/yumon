import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class DioClient {
  DioClient(this._storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  final SecureStorageService _storage;
  final Dio dio;

  ApiException readableError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return ApiException(data['message'].toString());
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return const ApiException(
          'No internet connection or server is offline.',
        );
      }
      return ApiException(error.message ?? 'Request failed.');
    }
    return ApiException(error.toString());
  }
}
