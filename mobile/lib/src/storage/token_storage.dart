import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // Keys
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  // On Web, flutter_secure_storage behaves differently depending on platform support.
  // For your school project, we keep a simple fallback: store in memory for web.
  // (If you want, later we can add a proper web storage adapter.)
  String? _webAccess;
  String? _webRefresh;

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    if (kIsWeb) {
      _webAccess = accessToken;
      _webRefresh = refreshToken;
      return;
    }
    await _secure.write(key: _kAccessToken, value: accessToken);
    await _secure.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<String?> readAccessToken() async {
    if (kIsWeb) return _webAccess;
    return _secure.read(key: _kAccessToken);
  }

  Future<String?> readRefreshToken() async {
    if (kIsWeb) return _webRefresh;
    return _secure.read(key: _kRefreshToken);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _webAccess = null;
      _webRefresh = null;
      return;
    }
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
  }
}