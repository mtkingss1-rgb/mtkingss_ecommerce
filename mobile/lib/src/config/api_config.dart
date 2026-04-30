import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator needs 10.0.2.2 to see your computer's localhost
        return 'http://10.0.2.2:3000'; 
      default:
        return 'http://127.0.0.1:3000';
    }
  }

  // Ensures these are built using the dynamic baseUrl above
  static Uri get register => Uri.parse('$baseUrl/api/v1/auth/register');
  static Uri get login => Uri.parse('$baseUrl/api/v1/auth/login');
  static Uri get refresh => Uri.parse('$baseUrl/api/v1/auth/refresh');
  static Uri get logout => Uri.parse('$baseUrl/api/v1/auth/logout');

  static Duration get requestTimeout => const Duration(seconds: 15);
}