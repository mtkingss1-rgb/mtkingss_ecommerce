import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiClient {
  Uri _u(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> getJson(String path) async {
    final r = await http.get(_u(path));
    final body = r.body.trim();
    final json = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = (json is Map && json['message'] != null) ? json['message'].toString() : 'HTTP ${r.statusCode}';
      throw Exception(msg);
    }

    return (json is Map<String, dynamic>) ? json : <String, dynamic>{'data': json};
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final text = r.body.trim();
    final json = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = (json is Map && json['message'] != null) ? json['message'].toString() : 'HTTP ${r.statusCode}';
      throw Exception(msg);
    }

    return (json is Map<String, dynamic>) ? json : <String, dynamic>{'data': json};
  }
}