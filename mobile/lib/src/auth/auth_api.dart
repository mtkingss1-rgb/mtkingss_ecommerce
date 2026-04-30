import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthApi {
  Future<Map<String, dynamic>> register({required String email, required String password}) async {
    final r = await http
        .post(
          ApiConfig.register,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(ApiConfig.requestTimeout);

    return _handle(r);
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final r = await http
        .post(
          ApiConfig.login,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(ApiConfig.requestTimeout);

    return _handle(r);
  }

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final r = await http
        .post(
          ApiConfig.refresh,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(ApiConfig.requestTimeout);

    return _handle(r);
  }

  Future<Map<String, dynamic>> logout({required String refreshToken}) async {
    final r = await http
        .post(
          ApiConfig.logout,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(ApiConfig.requestTimeout);

    return _handle(r);
  }

  Map<String, dynamic> _handle(http.Response r) {
    final text = r.body.trim();
    final json = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = (json is Map && json['message'] != null) ? json['message'].toString() : 'HTTP ${r.statusCode}';
      throw Exception(msg);
    }

    return (json is Map<String, dynamic>) ? json : <String, dynamic>{'data': json};
  }
}