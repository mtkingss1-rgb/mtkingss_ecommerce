import '../storage/token_storage.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({required this.api, required this.storage});

  final AuthApi api;
  final TokenStorage storage;

  Future<void> login({required String email, required String password}) async {
    final json = await api.login(email: email, password: password);
    
    // --- UPDATED: Accessing tokens directly from the json root ---
    await storage.saveTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Future<void> register({required String email, required String password}) async {
    final json = await api.register(email: email, password: password);
    
    // --- UPDATED: Accessing tokens directly from the json root ---
    await storage.saveTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Future<String?> getAccessToken() => storage.readAccessToken();
  Future<String?> getRefreshToken() => storage.readRefreshToken();

  Future<void> logout() async {
    final refresh = await storage.readRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await api.logout(refreshToken: refresh);
      } catch (e) {
        // Log error but proceed to clear local storage anyway
        print('Logout API call failed: $e');
      }
    }
    await storage.clear();
  }

  /// Returns a new access token (and stores rotated refresh token) if possible.
  /// Returns null if refresh is missing or invalid.
  Future<String?> tryRefresh() async {
    final refresh = await storage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final json = await api.refresh(refreshToken: refresh);
      
      // --- UPDATED: Accessing tokens directly from the json root ---
      final newAccess = json['accessToken'] as String;
      final newRefresh = json['refreshToken'] as String;

      await storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      return newAccess;
    } catch (e) {
      print('Token refresh failed, logging out: $e');
      // If refresh fails, the session is unrecoverable. Log out and throw.
      await logout();
      throw Exception('Your session has expired. Please log in again.');
    }
  }

  /// Compatibility method required by AuthedApiClient.
  Future<void> refreshTokens() async {
    final newAccess = await tryRefresh();
    if (newAccess == null || newAccess.isEmpty) {
      throw Exception('Could not refresh session');
    }
  }
}