import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/errand.dart';
import '../models/user.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _http;
  final String baseUrl;
  String? _token;

  static const _timeout = Duration(seconds: 20);

  void setToken(String? token) => _token = token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({required bool authenticated}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final uri = _uri(path);
    final encodedBody = body == null ? null : jsonEncode(body);
    final headers = _headers(authenticated: authenticated);

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response = await _http.post(
            uri,
            headers: headers,
            body: encodedBody,
          ).timeout(_timeout);
        default:
          throw StateError('Unsupported HTTP method: $method');
      }
    } on http.ClientException {
      throw const ApiException(
        statusCode: null,
        code: 'NETWORK_ERROR',
        message: 'Cannot reach the server. Check your connection and try again.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: null,
        code: 'TIMEOUT',
        message: 'The server took too long to respond. Please try again.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const ApiException(
          statusCode: null,
          code: 'BAD_RESPONSE',
          message: 'The server returned an unexpected response.',
        );
      }
    }
    throw ApiException.fromResponse(response);
  }

  Future<Map<String, dynamic>> _map(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final result = await _send(method, path, body: body, authenticated: authenticated);
    if (result is Map) return Map<String, dynamic>.from(result);
    throw const ApiException(
      statusCode: null,
      code: 'BAD_RESPONSE',
      message: 'The server returned an unexpected response.',
    );
  }

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final result = await _send('GET', path);
    if (result is List) {
      return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    throw const ApiException(
      statusCode: null,
      code: 'BAD_RESPONSE',
      message: 'The server returned an unexpected response.',
    );
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final data = await _map(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role.wireValue,
      },
      authenticated: false,
    );
    return User.fromJson(data);
  }

  Future<String> login({required String email, required String password}) async {
    final data = await _map(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return data['access_token'] as String;
  }

  Future<User> me() async {
    final data = await _map('GET', '/auth/me');
    return User.fromJson(data);
  }

  Future<void> logout() async {
    await _send('POST', '/auth/logout');
  }

  Future<Errand> createErrand({
    required String title,
    required String description,
    required String pickupAddress,
    required String dropoffAddress,
  }) async {
    final data = await _map(
      'POST',
      '/errands',
      body: {
        'title': title,
        'description': description,
        'pickup_address': pickupAddress,
        'dropoff_address': dropoffAddress,
      },
    );
    return Errand.fromJson(data);
  }

  Future<List<Errand>> myErrands() async {
    final rows = await _list('/errands/mine');
    return rows.map(Errand.fromJson).toList();
  }

  Future<List<Errand>> openErrands() async {
    final rows = await _list('/errands/open');
    return rows.map(Errand.fromJson).toList();
  }

  Future<List<Errand>> assignedErrands() async {
    final rows = await _list('/errands/assigned');
    return rows.map(Errand.fromJson).toList();
  }

  Future<Errand> errandAction(String errandId, String action) async {
    final data = await _map('POST', '/errands/$errandId/$action');
    return Errand.fromJson(data);
  }
}
