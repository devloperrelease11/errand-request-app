import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  factory ApiException.fromResponse(http.Response response) {
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    final detail = data?['detail'];
    String message;
    if (detail is String) {
      message = detail;
    } else if (detail is List) {
      message = detail
          .map((item) => item is Map ? '${item['field']}: ${item['message']}' : '$item')
          .join('\n');
    } else {
      message = 'Request failed (${response.statusCode}).';
    }

    return ApiException(
      statusCode: response.statusCode,
      code: data?['code'] as String? ?? 'HTTP_ERROR',
      message: message,
    );
  }

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
