import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ Added for debugPrint
import 'package:http/http.dart' as http;
import '../auth/auth_repository.dart';
import '../config/api_config.dart';

class AuthedApiClient {
  AuthedApiClient({required this.auth});

  final AuthRepository auth;

  Uri _u(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: query == null || query.isEmpty ? null : query);
  }

  Future<Map<String, String>> _headers() async {
    final token = await auth.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response r) {
    final body = r.body.trim();
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  // ✅ UPGRADE 5: Added isRetry to prevent infinite loops
  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool isRetry = false, 
  }) async {
    final headers = await _headers();
    late http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(_u(path, query), headers: headers);
        break;
      case 'POST':
        response = await http.post(_u(path, query), headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'PATCH':
        response = await http.patch(_u(path, query), headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'DELETE':
        response = await http.delete(_u(path, query), headers: headers);
        break;
    }

    // ==========================================
    // ✅ UPGRADE 5: THE 401 SILENT INTERCEPTOR
    // ==========================================
    if (response.statusCode == 401 && !isRetry) {
      debugPrint("[API Interceptor] Token expired (401). Attempting silent refresh...");
      try {
        // Just wait for it to finish. If it fails, it will jump to the catch block.
        await auth.refreshTokens();

        debugPrint("[API Interceptor] Refresh successful! Retrying original request...");
        
        return _request(
          method: method,
          path: path,
          body: body,
          query: query,
          isRetry: true, 
        );
      } catch (e) {
        debugPrint("[API Interceptor] Silent refresh failed: $e");
        auth.logout();
      }
    }
    // ==========================================

    final json = _decode(response);
    
    // Only throw an error if it's NOT a 401 (or if it IS a 401 but the retry already failed)
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'HTTP ${response.statusCode}');
    }
    return json;
  }

  /// --- USER PRODUCTS ---
  Future<List<Map<String, dynamic>>> listProducts() async {
    final j = await _request(method: 'GET', path: '/api/v1/products');
    final raw = (j['products'] as List<dynamic>? ?? const []);
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// --- BAKONG PAYMENTS ---
  Future<Map<String, dynamic>> getBakongQR(String orderId) async {
    return _request(method: 'GET', path: '/api/v1/payments/qr/$orderId');
  }

  Future<Map<String, dynamic>> verifyPayment(String orderId) async {
    return _request(method: 'GET', path: '/api/v1/payments/verify/$orderId');
  }

  /// --- ORDERS ---
  Future<Map<String, dynamic>> checkoutCreateOrder() async {
    return _request(method: 'POST', path: '/api/v1/orders');
  }
}