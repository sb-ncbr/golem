import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';

class ApiResponse<T extends dynamic> {
  final bool success;
  final dynamic data;
  final String message;

  ApiResponse._({required this.success, this.data, this.message = ""});

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse._(success: false, data: null, message: message);
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'success': true,
        'data': dynamic data,
      } =>
        ApiResponse.success(data),
      {
        'success': false,
        'message': String message,
      } =>
        ApiResponse.error(message),
      _ => throw const FormatException('Failed to parse api response.')
    };
  }
}

class ApiService {
  late Dio dio;

  ApiService() {
    dio = _setupDio();
  }

  Future<ApiResponse> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get(path,
          data: data, queryParameters: queryParameters, options: options);
      return ApiResponse.fromJson(response.data);
    } catch (e) {
      return _handleResponseError(e);
    }
  }

  Future<ApiResponse> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post(path,
          data: data, queryParameters: queryParameters, options: options);
      return ApiResponse.fromJson(response.data);
    } catch (e) {
      return _handleResponseError(e);
    }
  }

  Future<ApiResponse> download(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path,
          options: Options(responseType: ResponseType.bytes));

      return ApiResponse.success(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          // we need to decode the json as the response type is bytes
          // in case of download
          final jsonString = utf8.decode(e.response!.data);
          return ApiResponse.fromJson(
              json.decode(jsonString) as Map<String, dynamic>);
        }
      }
      return _handleResponseError(e);
    }
  }

  ApiResponse _handleResponseError(Object e) {
    if (e is DioException) {
      if (e.response != null) {
        return ApiResponse.fromJson(e.response!.data);
      }
    }
    return ApiResponse.error('Something went wrong.');
  }

  Dio _setupDio() {
    final adapter = BrowserHttpClientAdapter();
    adapter.withCredentials = true;

    final options = BaseOptions(
      baseUrl: '${const String.fromEnvironment('GOLEM_API_URL')}/api/v1',
      headers: {'Accept': 'application/json'},
    );
    dio = Dio(options);
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(LogInterceptor(responseBody: true));

    return dio;
  }
}
