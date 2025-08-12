import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';

class ApiResponse {
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
    final response = await dio.get(path,
        data: data, queryParameters: queryParameters, options: options);

    return _handleRequest(response);
  }

  Future<ApiResponse> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await dio.post(path,
        data: data, queryParameters: queryParameters, options: options);

    return _handleRequest(response);
  }

  Future<Uint8List> download(
    String path, {
      Map<String, dynamic>? queryParameters
    }
  ) async {
    final response = await dio.get(path, options: Options(
        responseType: ResponseType.bytes
      ));


    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to download resource.');
    }
  }

  ApiResponse _handleRequest(Response<dynamic> response) {
    if (response.statusCode == 200) {
      return ApiResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch resource.');
    }
  }

  Dio _setupDio() {
    final adapter = BrowserHttpClientAdapter();
    adapter.withCredentials = true;

    final options = BaseOptions(
        baseUrl: 'http://localhost:8000/api/v1',
        headers: {'Accept': 'application/json'});
    dio = Dio(options);
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(LogInterceptor(responseBody: true));

    return dio;
  }
}
