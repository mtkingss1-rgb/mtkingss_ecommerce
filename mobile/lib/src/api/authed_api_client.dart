import 'dart:convert';
import 'dart:async'; // For Completer
import 'package:http/http.dart' as http;

import '../auth/auth_repository.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/admin_stats.dart'; 

class AuthedApiClient {
  AuthedApiClient({required this.auth});

  final AuthRepository auth;
  Completer<String?>? _refreshCompleter;

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

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'data': decoded};
  }

  Exception _httpError(http.Response r, Map<String, dynamic> json) {
    final msg =
        (json['message'] ?? json['error'] ?? 'HTTP ${r.statusCode}').toString();
    return Exception(msg);
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool retryOn401 = true,
  }) async {
    Future<http.Response> send() async {
      final headers = await _headers();

      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(_u(path, query), headers: headers).timeout(const Duration(seconds: 15));

        case 'POST':
          return http.post(
            _u(path, query),
            headers: headers,
            body: jsonEncode(body ?? {}),
          ).timeout(const Duration(seconds: 15));

        case 'PATCH':
          return http.patch(
            _u(path, query),
            headers: headers,
            body: jsonEncode(body ?? {}),
          ).timeout(const Duration(seconds: 15));

        case 'DELETE':
          return http.delete(_u(path, query), headers: headers).timeout(const Duration(seconds: 15));

        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    }

    try {
      var response = await send();

      if (response.statusCode == 401 && retryOn401) {
        // If a refresh is NOT already in progress, start one.
        if (_refreshCompleter == null) {
          print("[API Interceptor] Token expired (401). Starting silent refresh...");
          _refreshCompleter = Completer<String?>();
          try {
            final newAccessToken = await auth.tryRefresh();
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              _refreshCompleter!.complete(newAccessToken);
            } else {
              _refreshCompleter!.complete(null);
            }
          } catch (e) {
            _refreshCompleter!.completeError(e);
          }
        }

        // Wait for the single refresh operation to complete.
        final newAccessToken = await _refreshCompleter!.future;
        _refreshCompleter = null; // Reset for the next potential expiry.

        if (newAccessToken != null) {
          print("[API Interceptor] Refresh successful. Retrying original request to $path");
          // Retry the original request with the new token.
          response = await send();
        } else {
          print("[API Interceptor] Refresh failed. Logging out.");
          // If refresh fails, logout. The original error will be thrown.
          await auth.logout();
        }
      }

      var json = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _httpError(response, json);
      }

      return json;
    } on TimeoutException {
      throw Exception('Network timeout: The server took too long to respond. Please check your internet connection.');
    } catch (e) {
      // If the refresh completer was active and failed, it might throw here.
      // Ensure we clean up.
      if (_refreshCompleter != null) {
        _refreshCompleter = null;
      }
      rethrow;
    }
  }

  /// -------------------------
  /// USER
  /// -------------------------

  Future<Map<String, dynamic>> me() async {
    return _request(method: 'GET', path: '/api/v1/users/me');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    return _request(
      method: 'PATCH',
      path: '/api/v1/users/me',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
      },
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _request(
      method: 'POST',
      path: '/api/v1/users/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<Map<String, dynamic>> getAddresses() async {
    return _request(method: 'GET', path: '/api/v1/users/addresses');
  }

  Future<Map<String, dynamic>> addAddress({
    required String label,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    required bool isDefault,
  }) async {
    return _request(
      method: 'POST',
      path: '/api/v1/users/addresses',
      body: {
        'label': label,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'isDefault': isDefault,
      },
    );
  }

  Future<Map<String, dynamic>> updateAddress({
    required String id,
    required String label,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    required bool isDefault,
  }) async {
    return _request(
      method: 'PATCH',
      path: '/api/v1/users/addresses/$id',
      body: {
        'label': label,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'isDefault': isDefault,
      },
    );
  }

  Future<Map<String, dynamic>> deleteAddress({required String id}) async {
    return _request(method: 'DELETE', path: '/api/v1/users/addresses/$id');
  }

  Future<Map<String, dynamic>> listProducts({
    String q = '',
    String minPrice = '',
    String maxPrice = '',
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{};

    if (q.trim().isNotEmpty) query['q'] = q.trim();
    if (minPrice.trim().isNotEmpty) query['minPrice'] = minPrice.trim();
    if (maxPrice.trim().isNotEmpty) query['maxPrice'] = maxPrice.trim();
    if (sort.trim().isNotEmpty) query['sort'] = sort.trim();
    query['page'] = page.toString();
    query['limit'] = limit.toString();

    return _request(
      method: 'GET',
      path: '/api/v1/products',
      query: query,
    );
  }

  Future<Map<String, dynamic>> getProduct(String productId) async {
    final j = await _request(
      method: 'GET',
      path: '/api/v1/products/$productId',
    );
    
    return Map<String, dynamic>.from(j['product'] as Map);
  }

  Future<void> seedProducts() async {
    await _request(method: 'POST', path: '/api/v1/products/dev/seed');
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    await _request(
      method: 'POST',
      path: '/api/v1/cart',
      body: {
        'productId': productId,
        'quantity': quantity,
      },
    );
  }

  Future<Map<String, dynamic>> getCart() async {
    return _request(method: 'GET', path: '/api/v1/cart');
  }

  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String productId,
    required int quantity,
  }) async {
    return _request(
      method: 'PATCH',
      path: '/api/v1/cart/items/$productId',
      body: {'quantity': quantity},
    );
  }

  Future<void> removeFromCart({
    required String productId,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/api/v1/cart/items/$productId',
    );
  }

  Future<Map<String, dynamic>> checkoutCreateOrder({
    required String addressId,
    String paymentMethod = 'CASH_ON_DELIVERY',
  }) async {
    return _request(
      method: 'POST',
      path: '/api/v1/orders',
      body: {
        'addressId': addressId,
        'paymentMethod': paymentMethod,
      },
    );
  }

  // --> RESTORED: This was missing and causing your CheckoutPage error!
  Future<Map<String, dynamic>> getBakongQR(String orderId) async {
    return _request(
      method: 'GET',
      path: '/api/v1/payments/qr/$orderId',
    );
  }

  Future<Map<String, dynamic>> verifyPayment(String orderId) async {
    return _request(
      method: 'GET',
      path: '/api/v1/payments/verify/$orderId',
    );
  }

  Future<List<Order>> myOrders() async {
    final j = await _request(method: 'GET', path: '/api/v1/orders/my');

    final raw = (j['orders'] as List<dynamic>? ?? const []);

    return raw
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// -------------------------
  /// ADMIN
  /// -------------------------

  Future<AdminDashboardStats> adminDashboardStats() async {
    final j = await _request(method: 'GET', path: '/api/v1/admin/dashboard');

    final stats =
        (j['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{});

    return AdminDashboardStats.fromJson(stats);
  }

  Future<List<Order>> adminAllOrders() async {
    final j = await _request(method: 'GET', path: '/api/v1/admin/orders');

    final raw = (j['orders'] as List<dynamic>? ?? const []);

    return raw
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> adminUpdateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final j = await _request(
      method: 'PATCH',
      path: '/api/v1/admin/orders/$orderId/status',
      body: {'status': status},
    );

    return Order.fromJson(j['order'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> adminAllProducts() async {
    final j = await _request(method: 'GET', path: '/api/v1/admin/products');

    final raw = (j['products'] as List<dynamic>? ?? const []);

    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> adminCreateProduct({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
    required double priceUsd,
    required int stock,
  }) async {
    final j = await _request(
      method: 'POST',
      path: '/api/v1/admin/products',
      body: {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'priceUsd': priceUsd,
        'stock': stock,
      },
    );

    return Map<String, dynamic>.from(j['product'] as Map);
  }

  Future<Map<String, dynamic>> adminUpdateProduct({
    required String productId,
    required String title,
    required String description,
    required String imageUrl,
    required String category,
    required double priceUsd,
    required int stock,
  }) async {
    final j = await _request(
      method: 'PATCH',
      path: '/api/v1/admin/products/$productId',
      body: {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'priceUsd': priceUsd,
        'stock': stock,
      },
    );

    return Map<String, dynamic>.from(j['product'] as Map);
  }

  Future<void> adminDeleteProduct({
    required String productId,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/api/v1/admin/products/$productId',
    );
  }

  /// -------------------------
  /// ORDERS
  /// -------------------------

  Future<Map<String, dynamic>> getMyOrders() async {
    return _request(method: 'GET', path: '/api/v1/orders/my');
  }

  Future<Map<String, dynamic>> getOrderDetail({required String orderId}) async {
    return _request(method: 'GET', path: '/api/v1/orders/$orderId');
  }

  /// -------------------------
  /// REVIEWS
  /// -------------------------

  Future<Map<String, dynamic>> createReview({
    required String productId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    return _request(
      method: 'POST',
      path: '/api/v1/reviews',
      body: {
        'productId': productId,
        'rating': rating,
        'title': title,
        'comment': comment,
      },
    );
  }

  Future<Map<String, dynamic>> getProductReviews({
    required String productId,
  }) async {
    return _request(method: 'GET', path: '/api/v1/reviews/product/$productId');
  }

  Future<Map<String, dynamic>> getUserReviews() async {
    return _request(method: 'GET', path: '/api/v1/reviews/me');
  }

  Future<void> deleteReview({required String reviewId}) async {
    await _request(method: 'DELETE', path: '/api/v1/reviews/$reviewId');
  }

  /// -------------------------
  /// WISHLIST
  /// -------------------------

  Future<Map<String, dynamic>> addToWishlist({
    required String productId,
  }) async {
    return _request(
      method: 'POST',
      path: '/api/v1/wishlist',
      body: {'productId': productId},
    );
  }

  Future<Map<String, dynamic>> getWishlist() async {
    return _request(method: 'GET', path: '/api/v1/wishlist');
  }

  Future<void> removeFromWishlist({required String productId}) async {
    await _request(method: 'DELETE', path: '/api/v1/wishlist/$productId');
  }

  Future<Map<String, dynamic>> isInWishlist({
    required String productId,
  }) async {
    return _request(method: 'GET', path: '/api/v1/wishlist/$productId/check');
  }
}